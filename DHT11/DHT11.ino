#include <SimpleDHT.h>
#include <WiFi.h>
#include <WiFiManager.h>
#include <Firebase_ESP_Client.h>
#include <time.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"

// Firebase configuration
#define API_KEY "AIzaSyAgaAgBG95VTOu0ntyqpK5LkcBjPbli-n4"
#define DATABASE_URL "https://esp32-bd-8ac4d-default-rtdb.europe-west1.firebasedatabase.app/"

// Firebase objects
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;
WiFiManager wifiManager;

// Authentication and user identification
bool signupOK = false;
const char *userID = "AuCwrs4JriWNk3jserhfih2lR5j2"; // Firebase user ID
const char *rucherName = "rucher_TEST";              // Apiary name (French: rucher)
const char *rucheName = "ruche_TEST";                // Config name (French: ruche)

// DHT11 sensor on GPIO 15
SimpleDHT11 dht11(15);

// WiFi reset button configuration (GPIO 33)
#define WIFI_RESET_BUTTON_PIN 33  // GPIO pin for WiFi reset button
bool lastResetButtonState = HIGH; // Previous reset button state
unsigned long debounceT = 0;      // Reset button debounce timing
unsigned long debounceD = 50;     // Reset button debounce delay (ms)

// Monitoring thresholds (configurable from Firebase)
int tempThreshold = 30;    // Temperature alert threshold (°C)
int humThreshold = 80;     // Humidity alert threshold (%)
bool notifyEnabled = true; // Notification enable/disable flag

// Circular buffer system for offline data storage
#define BUFFER_SIZE 5 // Maximum buffered readings
struct DataRecord     // Structure for sensor data
{
  char timestamp[17]; // Timestamp in DD-MM-YYYY_HH:MM format
  int temp;           // Temperature reading
  int hum;            // Humidity reading
};
DataRecord buffer[BUFFER_SIZE]; // Circular buffer array
int bufStart = 0;               // Buffer start index
int bufEnd = 0;                 // Buffer end index

// Cover detection button configuration (GPIO 22)
#define COVER_BUTTON_PIN 22         // GPIO pin for cover button
bool lastButtonState = HIGH;        // Previous button state
bool buttonState = HIGH;            // Current button state
unsigned long lastDebounceTime = 0; // Debounce timing
unsigned long debounceDelay = 50;   // Debounce delay (ms)

// Timing control
unsigned long lastTime = 0;     // Last measurement timestamp
unsigned long interval = 60000; // Measurement interval (ms) - configurable

/**
 * Initial setup and configuration
 *
 * Initializes all system components :
 * - Serial communication for debugging
 * - GPIO pins for buttons with internal pull-up resistors
 * - WiFiManager for automatic WiFi connection with captive portal fallback
 * - NTP time synchronization required for Firebase SSL connections
 * - Firebase authentication and configuration
 *
 * The system will create "ESP32-Config" access point if no WiFi credentials
 * are saved or if connection fails, allowing users to configure WiFi through
 * the captive portal interface.
 */
void setup()
{
  Serial.begin(115200);                         // Initialize serial communication
  pinMode(COVER_BUTTON_PIN, INPUT_PULLUP);      // Configure cover button with pull-up
  pinMode(WIFI_RESET_BUTTON_PIN, INPUT_PULLUP); // Configure WiFi reset button with pull-up

  wifiManager.autoConnect("ESP32-Config"); // Connect to WiFi or create AP

  configTime(0, 0, "pool.ntp.org");   // Sync time for Firebase SSL
  config.api_key = API_KEY;           // Set Firebase API key
  config.database_url = DATABASE_URL; // Set Firebase database URL

  if (Firebase.signUp(&config, &auth, "", "")) // Anonymous authentication
  {
    signupOK = true; // Mark authentication successful
  }

  config.token_status_callback = tokenStatusCallback; // Handle token refresh
  Firebase.begin(&config, &auth);                     // Initialize Firebase
  Firebase.reconnectWiFi(true);                       // Enable auto-reconnect
}

/**
 * Get current timestamp in French format
 *
 * Retrieves current time from NTP server and formats it as DD-MM-YYYY_HH:MM
 * This timestamp serves as unique identifier for measurements in Firebase
 *
 * @return String timestamp in French format or "unknown_time" if NTP sync failed
 */
String getFormattedTime()
{
  struct tm timeinfo;
  if (!getLocalTime(&timeinfo)) // Get current time from NTP
  {
    return "unknown_time"; // Fallback if time sync failed
  }
  char buffer[17];                                               // Buffer for formatted timestamp
  strftime(buffer, sizeof(buffer), "%d-%m-%Y_%H:%M", &timeinfo); // French date format
  return String(buffer);
}

/**
 * Add sensor reading to circular buffer
 *
 * Stores timestamp and sensor data in circular buffer for offline resilience.
 * If buffer is full, overwrites oldest data (FIFO - First In, First Out).
 * This ensures data persistence during WiFi/Firebase connectivity issues.
 *
 * @param timestamp Formatted timestamp string (DD-MM-YYYY_HH:MM)
 * @param temp Temperature reading in Celsius
 * @param hum Humidity reading in percentage
 */
void addToBuffer(const char *timestamp, int temp, int hum)
{
  if ((bufEnd + 1) % BUFFER_SIZE == bufStart) // Check if buffer is full
  {
    bufStart = (bufStart + 1) % BUFFER_SIZE; // Overwrite oldest data
  }
  strncpy(buffer[bufEnd].timestamp, timestamp, sizeof(buffer[bufEnd].timestamp)); // Copy timestamp
  buffer[bufEnd].temp = temp;                                                     // Store temperature
  buffer[bufEnd].hum = hum;                                                       // Store humidity
  bufEnd = (bufEnd + 1) % BUFFER_SIZE;                                            // Advance end pointer
}

/**
 * Send all buffered data to Firebase
 *
 * Processes all sensor readings stored in circular buffer and transmits them
 * to Firebase Realtime Database. Analyzes readings against thresholds to
 * determine event types (data, temp_event, hum_event, both_event).
 * Only removes data from buffer after successful Firebase transmission.
 *
 * Event types:
 * - "data": Normal reading within thresholds
 * - "temp_event": Temperature exceeds threshold
 * - "hum_event": Humidity exceeds threshold
 * - "both_event": Both temperature and humidity exceed thresholds
 */
void sendDataFromBuffer()
{
  while (bufStart != bufEnd) // Process all buffered data
  {
    DataRecord *record = &buffer[bufStart]; // Get next record
    String path = String(userID) + "/" + String(rucherName) + "/" + String(rucheName) + "/measurements/" + String(record->timestamp);

    String type = "data"; // Default event type
    if (record->temp > tempThreshold && record->hum > humThreshold)
    {
      type = "both_event"; // Both thresholds exceeded
    }
    else if (record->temp > tempThreshold)
    {
      type = "temp_event"; // Temperature threshold exceeded
    }
    else if (record->hum > humThreshold)
    {
      type = "hum_event"; // Humidity threshold exceeded
    }

    FirebaseJson json;                            // Main JSON object
    FirebaseJson dataPackage;                     // Nested data package
    dataPackage.set("temperature", record->temp); // Add temperature reading
    dataPackage.set("humidity", record->hum);     // Add humidity reading

    json.set("type", type);                // Set event type
    json.set("data_package", dataPackage); // Add data package

    if (Firebase.RTDB.setJSON(&fbdo, path.c_str(), &json)) // Send to Firebase
    {
      bufStart = (bufStart + 1) % BUFFER_SIZE; // Remove from buffer on success
    }
    else
    {
      break;
    }
  }
}

/**
 * Sends a cover event to Firebase
 * Transmits a cover opened event when cover button is pressed
 * Used for immediate notification of hive cover manipulation
 */
void sendCoverEvent()
{
  if (!notifyEnabled) // Check if notifications enabled
    return;

  String timestamp = getFormattedTime(); // Get current timestamp
  String path = String(userID) + "/" + String(rucherName) + "/" + String(rucheName) + "/measurements/" + timestamp;

  FirebaseJson json;                 // Main JSON object
  FirebaseJson dataPackage;          // Nested data package
  dataPackage.set("temperature", 0); // No sensor data for cover event
  dataPackage.set("humidity", 0);    // No sensor data for cover event

  json.set("type", "cover_opened");      // Mark as cover opened event
  json.set("data_package", dataPackage); // Add empty data package

  if (Firebase.ready() && signupOK) // Check Firebase connection
  {
    Firebase.RTDB.setJSON(&fbdo, path.c_str(), &json); // Send to Firebase
  }
}

/**
 * Monitors cover button with debouncing
 * Detects cover button presses and triggers cover events
 * Implements software debouncing for reliable button detection
 */
void checkCoverButton()
{
  int reading = digitalRead(COVER_BUTTON_PIN); // Read current button state

  if (reading != lastButtonState) // State change detected
  {
    lastDebounceTime = millis(); // Reset debounce timer
  }
  if ((millis() - lastDebounceTime) > debounceDelay) // Debounce period passed
  {
    if (reading != buttonState) // Stable state change
    {
      buttonState = reading;  // Update button state
      if (buttonState == LOW) // Button pressed (LOW = pressed)
      {
        sendCoverEvent(); // Send cover opened event
      }
    }
  }
  lastButtonState = reading; // Store reading for next cycle
}

/**
 * Fetches configuration constants from Firebase
 * Downloads thresholds and settings from Firebase database
 * Updates local variables with remote configuration values
 */
void fetchConstantsFromDB()
{
  String basePath = String(userID) + "/" + String(rucherName) + "/" + String(rucheName) + "/constants/";
  String tempPath = basePath + "temperature";  // Temperature threshold path
  String humPath = basePath + "humidity";      // Humidity threshold path
  String intervalPath = basePath + "interval"; // Measurement interval path
  String notifyPath = basePath + "notify";     // Notification enable path

  if (Firebase.RTDB.getInt(&fbdo, tempPath.c_str())) // Fetch temperature threshold
  {
    tempThreshold = fbdo.intData(); // Update local threshold
  }

  if (Firebase.RTDB.getInt(&fbdo, humPath.c_str())) // Fetch humidity threshold
  {
    humThreshold = fbdo.intData(); // Update local threshold
  }

  if (Firebase.RTDB.getInt(&fbdo, intervalPath.c_str())) // Fetch measurement interval
  {
    interval = fbdo.intData(); // Update local interval
  }

  if (Firebase.RTDB.getBool(&fbdo, notifyPath.c_str())) // Fetch notification setting
  {
    notifyEnabled = fbdo.boolData(); // Update local setting
  }
}

/**
 * Monitors WiFi reset button for factory reset
 * Detects long press (3+ seconds) to reset WiFiManager settings
 * Implements debouncing and timing for reliable reset detection
 */
void checkWiFiResetButton()
{
  static unsigned long buttonPressTime = 0; // Track button press duration
  static bool buttonPressed = false;        // Track button state

  int reading = digitalRead(WIFI_RESET_BUTTON_PIN); // Read current button state

  if (reading != lastResetButtonState) // State change detected
  {
    debounceT = millis(); // Reset debounce timer
  }

  if ((millis() - debounceT) > debounceD) // Debounce period passed
  {
    if (reading == LOW && !buttonPressed) // Button just pressed
    {
      buttonPressed = true;       // Mark as pressed
      buttonPressTime = millis(); // Start timing
    }
    else if (reading == HIGH && buttonPressed) // Button released
    {
      buttonPressed = false; // Mark as released
    }
    else if (buttonPressed && (millis() - buttonPressTime > 3000)) // Long press detected
    {
      wifiManager.resetSettings(); // Clear WiFi credentials
      ESP.restart();               // Restart to apply reset
    }
  }

  lastResetButtonState = reading; // Store for next cycle
}

/**
 * Main program loop
 * Continuously monitors sensors, buttons, and handles data transmission
 * Manages periodic measurements, button events, and buffer transmission
 */
void loop()
{
  checkCoverButton();     // Monitor cover button
  checkWiFiResetButton(); // Monitor WiFi reset button
  fetchConstantsFromDB(); // Update configuration from Firebase

  unsigned long currentMillis = millis();   // Get current time
  if (currentMillis - lastTime >= interval) // Time for new measurement?
  {
    lastTime = currentMillis; // Update timing

    byte temp = 0, hum = 0;                  // Temperature and humidity variables
    int err = dht11.read(&temp, &hum, NULL); // Read DHT11 sensor

    if (err == SimpleDHTErrSuccess) // Sensor read successful?
    {
      String timestamp = getFormattedTime();     // Get formatted timestamp
      addToBuffer(timestamp.c_str(), temp, hum); // Add to circular buffer

      if (Firebase.ready() && signupOK) // Firebase connection ready?
      {
        sendDataFromBuffer(); // Transmit buffered data
      }
    }
  }
}