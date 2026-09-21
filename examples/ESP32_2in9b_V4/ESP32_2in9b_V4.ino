#include <GxEPD2_3C.h>
#include <epd3c/GxEPD2_290_C90c.h>
#include <SimpleDHT.h>
#include <math.h>

// Waveshare 2.9" B V4, 128x296, 3-color panel.
// If the panel label is GDEH029Z13, use GxEPD2_290_Z13c instead.
GxEPD2_3C<GxEPD2_290_C90c, GxEPD2_290_C90c::HEIGHT> display(
  GxEPD2_290_C90c(/*CS=*/ 27, /*DC=*/ 26, /*RST=*/ 25, /*BUSY=*/ 34));

static const int DHT_PIN = 14;
static const int LIGHT_PIN = 33;
static const unsigned long UPDATE_INTERVAL_MS = 60000UL;
SimpleDHT11 dht11(DHT_PIN);
unsigned long lastUpdate = UPDATE_INTERVAL_MS;

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
    float a = i * 0.785398f;
    int x1 = cx + (int)(10 * cos(a));
    int y1 = cy + (int)(10 * sin(a));
    int x2 = cx + (int)(16 * cos(a));
    int y2 = cy + (int)(16 * sin(a));
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

void readAndDisplay()
{
  byte temperature = 0;
  byte humidity = 0;
  int dhtError = dht11.read(&temperature, &humidity, NULL);
  bool dhtValid = (dhtError == SimpleDHTErrSuccess);

  int rawLight = analogRead(LIGHT_PIN);
  bool lightValid = (rawLight >= 0 && rawLight <= 4095);
  int lightPercent = lightValid ? map(rawLight, 0, 4095, 0, 100) : 0;

  Serial.print("Temperature: ");
  Serial.print(dhtValid ? String(temperature) : "ERR");
  Serial.print(" C, Humidity: ");
  Serial.print(dhtValid ? String(humidity) : "ERR");
  Serial.print(" %RH, Light: ");
  Serial.print(lightValid ? String(lightPercent) : "ERR");
  Serial.println(" %");

  updateDisplay(dhtValid, temperature, dhtValid, humidity, lightValid, lightPercent);
}

void setup()
{
  Serial.begin(115200);
  pinMode(LIGHT_PIN, INPUT);
  readAndDisplay();
  lastUpdate = millis();
}

void loop()
{
  if (millis() - lastUpdate >= UPDATE_INTERVAL_MS)
  {
    lastUpdate = millis();
    readAndDisplay();
  }
}
