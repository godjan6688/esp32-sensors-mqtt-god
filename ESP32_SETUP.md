# ESP32 + Waveshare 2.9 吋三色電子紙

本專案目標硬體：

- Waveshare 2.9-inch e-Paper B V4
- 解析度：128 x 296（橫向規格常寫成 296 x 128）
- 黑／白／紅三色
- Driver Board Rev2.1

## 已下載程式庫

程式庫放在 `libraries/`：

- `GxEPD2`：ESP32 SPI 電子紙驅動
- `Adafruit-GFX-Library`：文字與圖形繪製相依套件
- `waveshare-e-paper`：微雪官方 Arduino 範例，保留作為控制器參考

Arduino IDE 也可以直接從 Library Manager 安裝 GxEPD2 與 Adafruit GFX。

## ESP32 接線（一般 ESP32 DevKit / VSPI）

| Driver Board Rev2.1 | ESP32 GPIO | 說明 |
|---|---:|---|
| VCC | 3V3 | 使用 3.3 V 供電 |
| GND | GND | 共地 |
| DIN / MOSI | GPIO 23 | SPI 資料 |
| CLK / SCK | GPIO 18 | SPI 時脈 |
| CS | GPIO 27 | SPI 選擇 |
| DC | GPIO 26 | 資料／命令選擇 |
| RST | GPIO 25 | 電子紙重置 |
| BUSY | GPIO 34 | 忙碌狀態輸入；GPIO34 僅能作輸入 |

若板上另有 `PWR` 腳，請接 `3V3`；未標示 `PWR` 的 Rev2.1 板不需額外接線。

注意事項：

1. ESP32 與電子紙都使用 3.3 V 邏輯；不要把 ESP32 GPIO 接到 5 V。
2. `BUSY` 是輸入腳，電子紙刷新期間程式會等待它釋放。
3. 電子紙刷新需要數秒，程式不可在刷新期間重複送資料。
4. 三色電子紙通常不適合頻繁局部刷新；優先使用全畫面刷新。

## 驅動類別確認

目前測試範例使用 `GxEPD2_290_C90c`，對應 128x296 的 SSD1680 三色面板。
若實際 FPC 或面板標籤顯示 `GDEH029Z13`，請將範例中的類別改成
`GxEPD2_290_Z13c`；兩者外觀相同但控制器初始化資料不同。

## 開啟範例

用 Arduino IDE 開啟：

`examples/ESP32_2in9b_V4/ESP32_2in9b_V4.ino`

選擇 ESP32 開發板與正確序列埠後上傳。範例會顯示黑色與紅色文字，完成後讓面板進入休眠。
