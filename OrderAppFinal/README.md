# 訂單畫面 iOS App — 修正版 v3

本版以原本 HTML 為基礎，針對 iPhone App 的 PNG 匯出及 Logo 顯示作修正：

- 送貨 Logo 由 40 × 40 px 放大至 60 × 60 px。
- 保留原本提供的 `delivery-logo.png` 外觀，但改為以 data URL 嵌入 HTML。
- PNG 匯出不再直接讀取本地圖片檔，避免 `WKWebView` / `file://` 導致 `SecurityError: The operation is insecure`。
- PNG 固定輸出 1320 × 2868 px。
- iPhone App 優先經 Swift `savePNG` bridge 儲存到相簿。
- 一般瀏覽器仍使用 Blob + download fallback。
- iPhone 預覽會按實際可用寬度自動縮放。
- 保留原有訂單、地址簿、狀態列及本地儲存功能。

第一次存 PNG 時，iOS 會要求相片新增權限；允許後即可儲存到相簿。

注意：`delivery-logo.png` 仍保留在 Resources 內，但 HTML 匯出時不再從該檔案載入。


## Logo update
- Logo remains 32×32 at the same position.
- Converted the delivery-box artwork to inline vector SVG for sharper PNG export.
- Slightly darker gray (`#7d7f83`) and thicker strokes.
