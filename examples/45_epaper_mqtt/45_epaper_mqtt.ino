#include <WiFi.h>
#include <PubSubClient.h>
#include <GxEPD2_3C.h>
#include <epd3c/GxEPD2_290_C90c.h>
#include <SimpleDHT.h>
#include <math.h>

// ============================================================
// Wi-Fi / MQTT settings
// 本版本使用手機熱點與 MQTTGO.io。
// ============================================================
const char* WIFI_SSID     = "Galaxy S24+ 29EB";
const char* WIFI_PASSWORD = "jan410250";

const char* MQTT_HOST     = "MQTTGO.io";
const uint16_t MQTT_PORT  = 1883;
const char* MQTT_USER     = "";
const char* MQTT_PASSWORD = "";

const char* MQTT_CLIENT_ID = "MQTTGO-6992413901";
const char* TOPIC_TEMPERATURE = "epaper/temperature";
const char* TOPIC_HUMIDITY    = "epaper/humidity";
const char* TOPIC_LIGHT       = "epaper/light";
const char* TOPIC_LAMP_SET    = "epaper/lamp/set";
const char* TOPIC_LAMP_STATE  = "epaper/lamp/state";

// 預設使用 ESP32 常見板載 LED 腳位；若是外接燈，請改成實際 GPIO。
// 不可使用 GPIO14（DHT11）或 GPIO33（光敏電阻）。
static const int LAMP_PIN = 2;
static const bool LAMP_ACTIVE_HIGH = true;

// Waveshare 2.9" B V4, 128x296, 3-color panel.
GxEPD2_3C<GxEPD2_290_C90c, GxEPD2_290_C90c::HEIGHT> display(
  GxEPD2_290_C90c(/*CS=*/ 27, /*DC=*/ 26, /*RST=*/ 25, /*BUSY=*/ 34));

static const int DHT_PIN = 14;
static const int LIGHT_PIN = 33;
static const unsigned long UPDATE_INTERVAL_MS = 60000UL;
static const unsigned long WIFI_RETRY_INTERVAL_MS = 15000UL;
static const unsigned long MQTT_RETRY_INTERVAL_MS = 5000UL;

SimpleDHT11 dht11(DHT_PIN);
WiFiClient wifiClient;
PubSubClient mqttClient(wifiClient);
unsigned long lastUpdate = UPDATE_INTERVAL_MS;
unsigned long lastWiFiAttempt = 0;
unsigned long lastMqttAttempt = 0;
bool lampOn = false;

void setLamp(bool on)
{
  lampOn = on;
  const bool outputHigh = LAMP_ACTIVE_HIGH ? on : !on;
  digitalWrite(LAMP_PIN, outputHigh ? HIGH : LOW);
}

void drawThermometer(int cx, int top)
{
  display.drawCircle(cx, top + 17, 6, GxEPD_RED);
  display.fillCircle(cx, top + 17, 3, GxEPD_RED);
  display.drawLine(cx, top + 2, cx, top + 17, GxEPD_RED);
  display.drawLine(cx + 4, top + 5, cx + 8, top + 5, GxEPD_BLACK);
  display.drawLine(cx + 4, top + 10, cx + 8, top + 10, GxEPD_BLACK);
  display.drawLine(cx + 4, top + 15, cx + 8, top + 15, GxEPD_BLACK);
}

void drawDroplet(int cx, int top)
{
  display.fillTriangle(cx, top, cx - 9, top + 14, cx + 9, top + 14, GxEPD_RED);
  display.fillCircle(cx, top + 12, 9, GxEPD_RED);
  display.drawTriangle(cx, top, cx - 9, top + 14, cx + 9, top + 14, GxEPD_BLACK);
  display.drawCircle(cx, top + 12, 9, GxEPD_BLACK);
}

void drawSun(int cx, int cy)
{
  display.fillCircle(cx, cy, 7, GxEPD_RED);
  display.drawCircle(cx, cy, 7, GxEPD_BLACK);
  for (int i = 0; i < 8; i++)
  {
    const float a = i * 0.785398f;
    const int x1 = cx + (int)(10 * cos(a));
    const int y1 = cy + (int)(10 * sin(a));
    const int x2 = cx + (int)(16 * cos(a));
    const int y2 = cy + (int)(16 * sin(a));
    display.drawLine(x1, y1, x2, y2, GxEPD_BLACK);
  }
}

void drawCenteredText(const char* text, int centerX, int y, uint16_t color)
{
  int16_t x1, y1;
  uint16_t tw, th;
  display.getTextBounds(text, 0, y, &x1, &y1, &tw, &th);
  display.setCursor(centerX - (int)tw / 2, y);
  display.setTextColor(color);
  display.print(text);
}

void drawCard(int x, const char* label, const char* value, const char* unit, int iconType)
{
  display.fillRect(x, 31, 87, 88, GxEPD_WHITE);
  display.drawRect(x, 31, 87, 88, GxEPD_BLACK);
  drawCenteredText(label, x + 43, 64, GxEPD_BLACK);

  if (iconType == 0) drawThermometer(x + 43, 39);
  if (iconType == 1) drawDroplet(x + 43, 39);
  if (iconType == 2) drawSun(x + 43, 50);

  drawCenteredText(value, x + 43, 84, GxEPD_RED);
  display.setTextColor(GxEPD_BLACK);
  display.setCursor(x + 61, 103);
  display.print(unit);
}

void updateDisplay(bool temperatureValid, int temperature, bool humidityValid, int humidity,
                   bool lightValid, int lightPercent)
{
  display.init(115200, true, 2, false);
  display.setRotation(1);
  display.setTextSize(1);
  display.setTextColor(GxEPD_BLACK);
  display.setFullWindow();
  display.firstPage();
  do
  {
    display.fillScreen(GxEPD_WHITE);
    display.setCursor(8, 16);
    display.setTextColor(GxEPD_BLACK);
    display.print("ENVIRONMENT");
    display.setTextColor(GxEPD_RED);
    display.setCursor(235, 16);
    display.print("60 SEC");
    display.drawLine(8, 24, 288, 24, GxEPD_RED);

    drawCard(8, "TEMP", temperatureValid ? String(temperature).c_str() : "ERR",
             "\xB0" "C", 0);
    drawCard(105, "HUM", humidityValid ? String(humidity).c_str() : "ERR",
             "%RH", 1);
    drawCard(202, "LIGHT", lightValid ? String(lightPercent).c_str() : "ERR",
             "%", 2);
  }
  while (display.nextPage());
  display.hibernate();
}

void publishMeasurements(bool dhtValid, byte temperature, byte humidity,
                         bool lightValid, int lightPercent)
{
  if (!mqttClient.connected()) return;

  if (dhtValid)
  {
    char temperatureText[8];
    char humidityText[8];
    snprintf(temperatureText, sizeof(temperatureText), "%u", temperature);
    snprintf(humidityText, sizeof(humidityText), "%u", humidity);
    mqttClient.publish(TOPIC_TEMPERATURE, temperatureText, true);
    mqttClient.publish(TOPIC_HUMIDITY, humidityText, true);
  }
  else
  {
    mqttClient.publish(TOPIC_TEMPERATURE, "ERR", true);
    mqttClient.publish(TOPIC_HUMIDITY, "ERR", true);
  }

  if (lightValid)
  {
    char lightText[8];
    snprintf(lightText, sizeof(lightText), "%d", lightPercent);
    mqttClient.publish(TOPIC_LIGHT, lightText, true);
  }
  else
  {
    mqttClient.publish(TOPIC_LIGHT, "ERR", true);
  }
}

void mqttCallback(char* topic, byte* payload, unsigned int length)
{
  if (strcmp(topic, TOPIC_LAMP_SET) != 0) return;

  String command;
  for (unsigned int i = 0; i < length; i++) command += (char)payload[i];
  command.trim();
  command.toUpperCase();

  if (command == "ON" || command == "1" || command == "TRUE")
  {
    setLamp(true);
    mqttClient.publish(TOPIC_LAMP_STATE, "ON", true);
  }
  else if (command == "OFF" || command == "0" || command == "FALSE")
  {
    setLamp(false);
    mqttClient.publish(TOPIC_LAMP_STATE, "OFF", true);
  }
}

void connectWiFi()
{
  if (WiFi.status() == WL_CONNECTED) return;
  if (millis() - lastWiFiAttempt < WIFI_RETRY_INTERVAL_MS) return;

  lastWiFiAttempt = millis();
  Serial.print("WiFi connecting to: ");
  Serial.println(WIFI_SSID);
  WiFi.mode(WIFI_STA);
  WiFi.setAutoReconnect(true);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
}

void connectMQTT()
{
  if (WiFi.status() != WL_CONNECTED || mqttClient.connected()) return;
  if (millis() - lastMqttAttempt < MQTT_RETRY_INTERVAL_MS) return;

  lastMqttAttempt = millis();
  Serial.print("MQTT connecting to: ");
  Serial.print(MQTT_HOST);
  Serial.print(":");
  Serial.println(MQTT_PORT);

  bool connected;
  if (strlen(MQTT_USER) == 0)
    connected = mqttClient.connect(MQTT_CLIENT_ID);
  else
    connected = mqttClient.connect(MQTT_CLIENT_ID, MQTT_USER, MQTT_PASSWORD);

  if (connected)
  {
    Serial.println("MQTT connected");
    mqttClient.subscribe(TOPIC_LAMP_SET);
    mqttClient.publish(TOPIC_LAMP_STATE, lampOn ? "ON" : "OFF", true);
  }
  else
  {
    Serial.print("MQTT failed, state=");
    Serial.println(mqttClient.state());
  }
}

void readDisplayAndPublish()
{
  byte temperature = 0;
  byte humidity = 0;
  const int dhtError = dht11.read(&temperature, &humidity, NULL);
  const bool dhtValid = (dhtError == SimpleDHTErrSuccess);

  const int rawLight = analogRead(LIGHT_PIN);
  const bool lightValid = (rawLight >= 0 && rawLight <= 4095);
  const int lightPercent = lightValid ? map(rawLight, 0, 4095, 0, 100) : 0;

  Serial.print("Temperature: ");
  Serial.print(dhtValid ? String(temperature) : "ERR");
  Serial.print(" C, Humidity: ");
  Serial.print(dhtValid ? String(humidity) : "ERR");
  Serial.print(" %RH, Light: ");
  Serial.print(lightValid ? String(lightPercent) : "ERR");
  Serial.println(" %");

  updateDisplay(dhtValid, temperature, dhtValid, humidity, lightValid, lightPercent);
  publishMeasurements(dhtValid, temperature, humidity, lightValid, lightPercent);
}

void setup()
{
  Serial.begin(115200);
  pinMode(LIGHT_PIN, INPUT);
  pinMode(LAMP_PIN, OUTPUT);
  setLamp(false);
  mqttClient.setServer(MQTT_HOST, MQTT_PORT);
  mqttClient.setCallback(mqttCallback);

  readDisplayAndPublish();
  lastUpdate = millis();
}

void loop()
{
  connectWiFi();
  connectMQTT();
  if (mqttClient.connected()) mqttClient.loop();

  if (millis() - lastUpdate >= UPDATE_INTERVAL_MS)
  {
    lastUpdate = millis();
    readDisplayAndPublish();
  }
}
