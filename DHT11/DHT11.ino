#include <SimpleDHT.h>
#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <time.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"

#define API_KEY ""
#define DATABASE_URL "https://esp32-bd-8ac4d-default-rtdb.europe-west1.firebasedatabase.app/"

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

bool signupOK = false;
const char *userID = "AuCwrs4JriWNk3jserhfih2lR5j2";

SimpleDHT11 dht11(15);

const char *ssid = "5 lei";
const char *password = "parolablanao";

int tempThreshold = 30;
int humThreshold = 80;

#define BUFFER_SIZE 5
struct DataRecord
{
  char timestamp[17];
  int temp;
  int hum;
};
DataRecord buffer[BUFFER_SIZE];
int bufStart = 0;
int bufEnd = 0;

unsigned long lastTime = 0;
unsigned long interval = 60000;

void setup()
{
  Serial.begin(115200);

  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED)
  {
    delay(1000);
  }

  configTime(0, 0, "pool.ntp.org");

  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;

  if (Firebase.signUp(&config, &auth, "", ""))
  {
    signupOK = true;
  }

  config.token_status_callback = tokenStatusCallback;
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
}

String getFormattedTime()
{
  struct tm timeinfo;
  if (!getLocalTime(&timeinfo))
  {
    return "unknown_time";
  }
  char buffer[17];
  strftime(buffer, sizeof(buffer), "%d-%m-%Y_%H:%M", &timeinfo);
  return String(buffer);
}

void addToBuffer(const char *timestamp, int temp, int hum)
{
  if ((bufEnd + 1) % BUFFER_SIZE == bufStart)
  {
    bufStart = (bufStart + 1) % BUFFER_SIZE;
  }
  strncpy(buffer[bufEnd].timestamp, timestamp, sizeof(buffer[bufEnd].timestamp));
  buffer[bufEnd].temp = temp;
  buffer[bufEnd].hum = hum;
  bufEnd = (bufEnd + 1) % BUFFER_SIZE;
}

void sendDataFromBuffer()
{
  while (bufStart != bufEnd)
  {
    DataRecord *record = &buffer[bufStart];
    String path = String(userID) + "/measurements/" + String(record->timestamp);

    String type = "data";
    String messageEvent = "";

    if (record->temp > tempThreshold && record->hum > humThreshold)
    {
      type = "both_event";
    }
    else if (record->temp > tempThreshold)
    {
      type = "temp_event";
    }
    else if (record->hum > humThreshold)
    {
      type = "hum_event";
    }

    FirebaseJson json;
    FirebaseJson dataPackage;
    dataPackage.set("temperature", record->temp);
    dataPackage.set("humidity", record->hum);

    json.set("type", type);
    json.set("data_package", dataPackage);

    if (Firebase.RTDB.setJSON(&fbdo, path.c_str(), &json))
    {
      bufStart = (bufStart + 1) % BUFFER_SIZE;
    }
    else
    {
      break;
    }
  }
}

void fetchThresholdsFromDB()
{
  String tempPath = String(userID) + "/threshold/temperature";
  String humPath = String(userID) + "/threshold/humidity";
  String intervalPath = String(userID) + "/threshold/interval";

  if (Firebase.RTDB.getInt(&fbdo, tempPath.c_str()))
  {
    tempThreshold = fbdo.intData();
  }

  if (Firebase.RTDB.getInt(&fbdo, humPath.c_str()))
  {
    humThreshold = fbdo.intData();
  }

  if (Firebase.RTDB.getInt(&fbdo, intervalPath.c_str()))
  {
    interval = fbdo.intData();
  }
}

void loop()
{
  unsigned long currentMillis = millis();
  if (currentMillis - lastTime >= interval)
  {
    lastTime = currentMillis;
    fetchThresholdsFromDB();

    byte temp = 0, hum = 0;
    int err = dht11.read(&temp, &hum, NULL);

    if (err == SimpleDHTErrSuccess)
    {
      String timestamp = getFormattedTime();
      addToBuffer(timestamp.c_str(), temp, hum);

      if (Firebase.ready() && signupOK)
      {
        sendDataFromBuffer();
      }
    }
  }
}