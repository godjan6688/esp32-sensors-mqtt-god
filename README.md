# ESP32 Sensors MQTT

ESP32 感測器與電子紙顯示整合專案，目標是將感測資料透過 MQTT 傳送，並在 2.9 吋電子紙上呈現狀態、數值與自訂圖像。

## 專案內容

- ESP32 感測器資料讀取範例
- MQTT 發布與訂閱範例
- 2.9 吋 Waveshare e-Paper（epd2in9b V4）驅動與示例
- GxEPD2、Adafruit GFX、SimpleDHT 等 Arduino 函式庫
- 電子紙顯示用字型、圖像與 Moon Rabbit 測試素材
- 硬體設定與交接紀錄

## 目錄結構

```text
.
├── examples/                # ESP32、電子紙、DHT 與 MQTT 範例
├── libraries/               # 專案使用的 Arduino 函式庫
├── tools/                   # 輔助工具與產生器
├── ESP32_SETUP.md           # ESP32 開發環境與硬體設定
├── 交接紀錄.md              # 開發交接與目前進度
└── *.png / *.svg            # 顯示與圖像素材
```

## 硬體需求

- ESP32 開發板
- 2.9 吋 Waveshare e-Paper，epd2in9b V4
- DHT11 或 DHT22 感測器（依使用的範例而定）
- MQTT Broker（若使用 MQTT 範例）
- USB 資料線與穩定的 3.3V 邏輯電源

## 開始使用

1. 安裝 Arduino IDE 或其他支援 ESP32 的開發環境。
2. 安裝 ESP32 Arduino Board Package。
3. 將本專案中的 `libraries/` 函式庫放入 Arduino libraries 目錄，或在 IDE 中加入函式庫。
4. 開啟 `examples/` 下對應的 `.ino` 範例。
5. 依硬體接線與使用情境修改 Wi-Fi、MQTT Broker、主題（topic）及感測器腳位。
6. 選擇正確的 ESP32 開發板與序列埠後編譯、上傳。

詳細硬體與開發環境設定請參考 [`ESP32_SETUP.md`](ESP32_SETUP.md)。

## MQTT 設定注意事項

請勿將 Wi-Fi 密碼、MQTT 帳號、密碼或其他私密憑證直接提交到公開 repository。建議使用未追蹤的本機設定檔，例如：

```cpp
// local_secrets.h（請勿提交）
const char* WIFI_SSID = "your-ssid";
const char* WIFI_PASSWORD = "your-password";
const char* MQTT_HOST = "broker.example.com";
```

`.gitignore` 已排除常見的 secrets、credentials 與環境設定檔名稱；提交前仍請檢查 `git diff --cached`。

## 編譯輸出

Arduino/ESP32 編譯產生的中間檔與 binary 不納入版本控制。這些輸出通常會出現在 `.build_*` 或 `build/` 目錄，並已由 `.gitignore` 排除。

## 授權

本專案中的第三方函式庫保留其原始授權條款，請參閱各函式庫目錄內的 `LICENSE`、`README` 或 `library.properties`。本專案自有程式碼的授權方式可再依維護者需求補充。
