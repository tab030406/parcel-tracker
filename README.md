# 郵局包裹自動查詢（GitHub Actions 排程版）

## 這個資料夾裡有什麼

- `index.html` — 查詢頁面，讀取 `results.json` 顯示結果，也可手動新增號碼即時查詢
- `parcels.json` — 要追蹤的包裹清單（號碼＋標籤），自行增減
- `scripts/track.sh` — 實際去問中華郵政的腳本
- `.github/workflows/track-parcels.yml` — 排程設定，每 2 小時自動跑一次 `track.sh`
- `results.json` — 由排程自動產生，**不用自己建**，第一次跑完就會出現

## 部署步驟

1. 到 GitHub 建立一個新的 repository（例如 `parcel-tracker`），或直接放進你現有的 `order-tool` repo 的子資料夾。
2. 把這個資料夾裡的所有檔案（含 `.github` 這個隱藏資料夾）上傳上去，保持原本的路徑結構。
3. 到 repo 的 **Settings → Actions → General**，把「Workflow permissions」設成 **Read and write permissions**（這樣排程才有權限把 `results.json` 推回 repo）。
4. 到 **Settings → Pages**，把 GitHub Pages 來源設定成你放這些檔案的分支（通常是 `main`），存檔後會拿到一個網址，例如 `https://tab030406.github.io/parcel-tracker/`。
5. 到 repo 上方的 **Actions** 分頁，點進「查詢郵局包裹進度」這個 workflow，按右邊的 **Run workflow** 手動觸發一次，確認能成功跑完並產生 `results.json`。
6. 之後就會照 `.github/workflows/track-parcels.yml` 裡設定的時間（預設每 2 小時）自動執行，不用再手動做任何事。

## 之後想調整

- **改查詢間隔**：修改 `track-parcels.yml` 裡的 `cron: "0 */2 * * *"`，例如改成 `"0 * * * *"` 就是每小時查一次。
- **增加/刪除要追蹤的包裹**：直接編輯 `parcels.json`，下次排程跑的時候就會照新清單查。
- **想要有更新就收到通知**：可以在 workflow 最後加一段，把有異動的包裹狀態發到 Telegram / Email / Slack，需要的話跟我說一聲，我再幫你補上。

## 小提醒

- `track.sh` 是直接呼叫中華郵政官網查詢頁背後使用的同一組介面，格式可能哪天會被調整；如果排程突然查不到資料，多半是介面格式變了，需要更新腳本。
- `results.json` 是查詢紀錄，只包含 `parcels.json` 裡設定的號碼、時間與狀態文字，沒有個資疑慮。
