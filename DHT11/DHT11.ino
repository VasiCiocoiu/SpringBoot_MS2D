#include <SimpleDHT.h>
#include <time.h>
#include <Arduino.h>
#include "BluetoothSerial.h"
#if defined(ESP32)
  #include <WiFi.h>
#elif defined(ESP8266)
  #include <ESP8266WiFi.h>
#endif
#include <Firebase_ESP_Client.h>
#include <WiFiManager.h> // Include WiFiManager library

// Provide the token generation process info.
#include "addons/TokenHelper.h"
// Provide the RTDB payload printing info and other helper functions.
#include "addons/RTDBHelper.h"

// Insert Firebase project API Key
#define API_KEY ""

// Insert RTDB URL
#define DATABASE_URL "https://esp32-bd-8ac4d-default-rtdb.europe-west1.firebasedatabase.app/" 

// Define Firebase Data object
FirebaseData fbdo;

FirebaseAuth auth;
FirebaseConfig config;
BluetoothSerial SerialBT;

unsigned long sendDataPrevMillis = 0;
bool signupOK = false;
const String userID = "AuCwrs4JriWNk3jserhfih2lR5j2";

bool bluetoothConnected = false;
String bluetoothCommand = "";



const char* ntpServer = "pool.ntp.org"; // NTP server
const long gmtOffset_sec = 3600;      // GMT offset in seconds
const int daylightOffset_sec = 3600;   // Daylight saving time offset

// for DHT11, 
//      VCC: 5V or 3V
//      GND: GND
//      DATA: 15
int pinDHT11 = 15;
SimpleDHT11 dht11(pinDHT11);

// WiFiManager setup
WiFiManager wm; // Create an instance of WiFiManager
const char* ap_ssid = "ESP32"; // Access Point SSID 
const char* ap_password = "12345678"; // Access Point Password 

int temperatureThreshold = 30; // Temperature threshold
int humidityThreshold = 80; // Humidity threshold

// Buffer to store unsent data
#define BUFFER_SIZE 10
struct DataRecord {
  char timestamp[20];
  int temperature;
  int humidity;
};
DataRecord buffer[BUFFER_SIZE];
int bufferStart = 0;
int bufferEnd = 0;

unsigned long lastTime = 0; // Store the last time 
unsigned long timeInterval = 60000; // Interval to fetch (1 minute)

// Define the GPIO pin for the reset button
#define RESET_BUTTON_PIN 33

void setup() {
  Serial.begin(115200);
  Serial.println("Starting setup...");

  // Configure the reset button pin
  pinMode(RESET_BUTTON_PIN, INPUT_PULLUP); // Use internal pull-up resistor

  // Configure Wi-Fi mode to Station (STA)
  WiFi.mode(WIFI_STA);

  // Initialize WiFiManager to connect to any Wi-Fi
  if (!wm.autoConnect(ap_ssid, ap_password)) {
    Serial.println("Failed to connect to Wi-Fi."); // Log failure to connect
  } else {
    Serial.println("Wi-Fi connected successfully!"); // Log successful connection
  }

  // Initialize NTP
  configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);
  Serial.println("NTP time synchronization initialized.");

  // Assign the API key and database URL
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;

  // Sign up to Firebase
  if (Firebase.signUp(&config, &auth, "", "")) {
    Serial.println("Firebase signup successful.");
    signupOK = true;
  } else {
    Serial.printf("Firebase signup failed: %s\n", config.signer.signupError.message.c_str());
  }

  // Assign the callback function for the long-running token generation task
  config.token_status_callback = tokenStatusCallback;

  // Initialize Firebase
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  SerialBT.begin("ESP32_DHT11_Monitor"); // Bluetooth device name
  Serial.println("Bluetooth device started, now you can pair it with bluetooth!");
}

String getFormattedTime() {
  struct tm timeinfo;
  if (!getLocalTime(&timeinfo)) {
    Serial.println("Failed to obtain time");
    return "unknown_time";
  }
  char buffer[17]; // Buffer for "DD-MM-YYYY_HH:MM"
  strftime(buffer, sizeof(buffer), "%d-%m-%Y_%H:%M", &timeinfo); // Format time as DD-MM-YYYY_HH:MM
  return String(buffer);
}

void addToBuffer(const char* timestamp, int temperature, int humidity) {
  if ((bufferEnd + 1) % BUFFER_SIZE == bufferStart) {
    Serial.println("Buffer is full, overwriting oldest data.");
    bufferStart = (bufferStart + 1) % BUFFER_SIZE; // Overwrite oldest data
  }
  strncpy(buffer[bufferEnd].timestamp, timestamp, sizeof(buffer[bufferEnd].timestamp));
  buffer[bufferEnd].temperature = temperature;
  buffer[bufferEnd].humidity = humidity;
  bufferEnd = (bufferEnd + 1) % BUFFER_SIZE;
}

void sendDataFromBuffer() {
  while (bufferStart != bufferEnd) {
    DataRecord* record = &buffer[bufferStart];
    String path = userID +"/measurements/" + String(record->timestamp);

    // Determine the type and message_event
    String type = "data";
    String messageEvent = "";
    if (record->temperature > temperatureThreshold || record->humidity > humidityThreshold) {
      type = "event";
      if (record->temperature > temperatureThreshold && record->humidity > humidityThreshold) {
        messageEvent = "La température (" + String(record->temperature) + "°C) et l'humidité (" + String(record->humidity) + "%) ont dépassé leurs seuils. Seuils : température (" + String(temperatureThreshold) + "°C), humidité (" + String(humidityThreshold) + "%).";
            } else if (record->temperature > temperatureThreshold) {
        messageEvent = "La température (" + String(record->temperature) + "°C) a dépassé son seuil. Seuil : température (" + String(temperatureThreshold) + "°C).";
            } else if (record->humidity > humidityThreshold) {
        messageEvent = "L'humidité (" + String(record->humidity) + "%) a dépassé son seuil. Seuil : humidité (" + String(humidityThreshold) + "%).";
      }
    }

    // Create the JSON object
    FirebaseJson json;
    FirebaseJson dataPackage;
    dataPackage.set("temperature", record->temperature);
    dataPackage.set("humidity", record->humidity);

    json.set("type", type);
    if (type == "event") {
      json.set("message_event", messageEvent.c_str());
    }
    json.set("data_package", dataPackage);

    // Send the JSON object to Firebase
    if (Firebase.RTDB.setJSON(&fbdo, path.c_str(), &json)) {
      Serial.println("Data upload PASSED");
      bufferStart = (bufferStart + 1) % BUFFER_SIZE; // Remove successfully sent data
    } else {
      Serial.println("Data upload FAILED: " + fbdo.errorReason());
      break; // Stop trying to send if one fails
    }
  }
}

// Check if the thresholds are updated in Firebase
void fetchThresholdsFromDB() {
  String temperaturePath = userID + "/threshold/temperature";
  String humidityPath = userID + "/threshold/humidity";
  String intervalPath = userID + "/threshold/interval";

  // Fetch temperature threshold
  if (Firebase.RTDB.getInt(&fbdo, temperaturePath.c_str())) {
    temperatureThreshold = fbdo.intData(); // Update the temperature threshold
    Serial.printf("Updated temperatureThreshold: %d\n", temperatureThreshold);
  } else {
    Serial.printf("Failed to fetch temperatureThreshold: %s\n", fbdo.errorReason().c_str());
  }

  // Fetch humidity threshold
  if (Firebase.RTDB.getInt(&fbdo, humidityPath.c_str())) {
    humidityThreshold = fbdo.intData(); // Update the humidity threshold
    Serial.printf("Updated humidityThreshold: %d\n", humidityThreshold);
  } else {
    Serial.printf("Failed to fetch humidityThreshold: %s\n", fbdo.errorReason().c_str());
  }

  // Fetch time interval
  if (Firebase.RTDB.getInt(&fbdo, intervalPath.c_str())) {
    timeInterval = fbdo.intData(); // Update the time interval (already in milliseconds)
    Serial.printf("Updated timeInterval: %lu ms\n", timeInterval);
  } else {
    Serial.printf("Failed to fetch timeInterval: %s\n", fbdo.errorReason().c_str());
  }
}


void checkBluetoothConnection() {
  if (SerialBT.available()) {
    String message = SerialBT.readString();
    message.trim();
    Serial.println("Bluetooth received: " + message);
    SerialBT.println("ESP32 connected and received: " + message);
  }
}

// Main loop
void loop() {
  // Check if the reset button is pressed
  if (digitalRead(RESET_BUTTON_PIN) == LOW) { // Button is active
    Serial.println("Resetting Wi-Fi settings and restarting...");
    wm.resetSettings(); // Clear Wi-Fi credentials
    ESP.restart(); // Restart the ESP32
  }

  checkBluetoothConnection();

  //Fetch thresholds from the database
    unsigned long currentMillis = millis();
    if (currentMillis - lastTime >= timeInterval) {
      lastTime = currentMillis; // Update the last fetch time
      fetchThresholdsFromDB(); // Fetch thresholds

      Serial.println("=================================");
      Serial.println("Reading DHT11...");

      byte temperature = 0, humidity = 0;
      int err = dht11.read(&temperature, &humidity, NULL);

      // Read without samples.
      if (err != SimpleDHTErrSuccess) {
        Serial.printf("Read DHT11 failed, err=%d, duration=%d\n", SimpleDHTErrCode(err), SimpleDHTErrDuration(err));
        return;
      }

      Serial.printf("Sample OK: %d *C, %d H\n", temperature, humidity);

      // Add the data to the buffer
      String timestamp = getFormattedTime();
      addToBuffer(timestamp.c_str(), temperature, humidity);

      // Attempt to send data from the buffer
      if (Firebase.ready() && signupOK) {
        sendDataFromBuffer();
      } else {
        Serial.println("Firebase not ready or signup failed.");
      }
    }
}
