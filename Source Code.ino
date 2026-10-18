#include <WiFi.h>
#include <HTTPClient.h>
#include "DHT.h"

#define DHTPIN 26
#define DHTTYPE DHT22

DHT dht(DHTPIN, DHTTYPE);

const char* ssid = "Wokwi-GUEST";
const char* password = "";

const char* writeAPIKey = "YOUR_WRITE_API_KEY";

void setup() {
  Serial.begin(115200);

  dht.begin();

  Serial.println("Connecting to Wi-Fi...");

  WiFi.begin(ssid, password, 6);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println();
  Serial.println("Wi-Fi Connected!");
}

void loop() {

  float temperature = dht.readTemperature();
  float humidity = dht.readHumidity();

  if (isnan(temperature) || isnan(humidity)) {
    Serial.println("Failed to read DHT22");
    delay(2000);
    return;
  }

  Serial.print("Temperature: ");
  Serial.print(temperature);
  Serial.println(" °C");

  Serial.print("Humidity: ");
  Serial.print(humidity);
  Serial.println(" %");

  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;

    String url = "https://api.thingspeak.com/update?api_key=";
    url += writeAPIKey;
    url += "&field1=";
    url += String(temperature);
    url += "&field2=";
    url += String(humidity);

    http.begin(url);
    int httpResponseCode = http.GET();

    // Check the HTTP status code first
    Serial.print("ThingSpeak HTTP status: ");
    Serial.println(httpResponseCode);

    if (httpResponseCode > 0) {
      // A positive status means the server replied, so read the body
      String responseBody = http.getString();

      Serial.print("ThingSpeak response body: ");
      Serial.println(responseBody);

      if (httpResponseCode == HTTP_CODE_OK) {
        // HTTP 200 = server answered; the body shows if an entry was stored
        if (responseBody.toInt() > 0) {
          Serial.println("ThingSpeak entry stored successfully.");
        } else {
          Serial.println("No new ThingSpeak entry was created.");
        }
      } else {
        Serial.println("ThingSpeak returned an HTTP error.");
      }
    } else {
      Serial.println("ThingSpeak HTTP request failed.");
      Serial.println(http.errorToString(httpResponseCode));
    }

    http.end();
  } else {
    Serial.println("Wi-Fi disconnected. Upload skipped.");
  }

  Serial.println("--------------------");

  delay(15000);
}
