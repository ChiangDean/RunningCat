# OAuth 手動驗收清單

## 環境前提

- API 已設定 `Google` / `Apple` / `LINE` 的 OAuth client id / secret
- provider console 的 redirect URI 指向 API：
  - `/api/auth/oauth/google/callback`
  - `/api/auth/oauth/apple/callback`
  - `/api/auth/oauth/line/callback`
- client `runtime_config.local.json` 指向對應 API base URL

## StartScene 驗收

1. 使用帳密登入仍可正常進入遊戲。
2. `Google` / `Apple` / `LINE` 三個 OAuth 按鈕都會顯示在登入表單下方。
3. 點任一 OAuth 按鈕後，會開啟授權頁，且登入表單進入等待狀態。
4. 若授權被取消，畫面會顯示取消訊息，不會卡死。
5. 若授權超時，畫面會提示重新嘗試。
6. 首次第三方登入成功後，會進入輸入 `playerName` 的畫面。
7. 首次命名成功後，會取得 session 並進入 bootstrap。
8. 已綁定過的第三方帳號再次登入時，不需重新命名。
9. 若 provider email 對應到既有帳密帳號，會顯示衝突提示，不自動合併。

## ConfigScene 驗收

1. 帳號區塊可看到目前登入方式。
2. `Google` / `Apple` / `LINE` 三張卡片都能正確顯示 `已綁定` / `未綁定`。
3. 已綁定的 provider 顯示 `解除綁定`。
4. 未綁定的 provider 顯示 `綁定`。
5. 點 `綁定` 後會開啟授權頁，完成後卡片會即時更新成 `已綁定`。
6. 點 `解除綁定` 後會先出現確認視窗。
7. 若帳號沒有密碼登入，且只剩最後一個 OAuth 綁定，解除按鈕應不可用。
8. 若解除的是目前登入方式，成功後應強制回到登入頁。
9. 若解除的不是目前登入方式，應留在設定中心並更新卡片狀態。

## 多裝置驗收

1. 同帳號在不同裝置登入，彼此 session 可共存。
2. 同帳號同裝置重新登入後，舊 refresh token 應失效。
3. 解除目前登入方式後，當前裝置應立即失去 session。

## 例外情境驗收

1. provider console 關閉或設定錯誤時，前端需顯示失敗訊息。
2. API 無法連線時，前端需顯示 request error / timeout。
3. callback 交易過期時，需顯示超時訊息。
4. 同一個 provider 已綁到其他帳號時，設定中心需顯示綁定失敗。

## 後端整合測試對應項目

- login happy path
- first login needs profile name
- account conflict requires bind
- link success
- unlink current login method
- unlink last available login method fail
- provider subject normalization uniqueness
- audit log success / failure
