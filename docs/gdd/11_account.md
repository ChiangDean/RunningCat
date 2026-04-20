# 帳號系統

| 項目 | 說明 |
| --- | --- |
| 帳密登入 | `account + password` |
| 第三方登入 | `Google` / `Apple` / `LINE` |
| 登入入口 | `StartScene` |
| 設定中心入口 | 首頁左上角角色卡片，開啟 `ConfigScene` |
| 帳號識別 | 以後端 `UserExternalLogin` 綁定為準，不依 email 自動合併帳號 |
| OAuth 建號規則 | 首次第三方登入成功後，必須先輸入 `playerName` 才會建立帳號 |
| 綁定管理 | 設定中心可顯示目前登入方式、已綁定方式、綁定 / 解除綁定 |
| 登出入口 | `StartScene` 與 `ConfigScene` 都可安全登出 |

## StartScene 流程

1. 預設顯示帳號密碼登入表單。
2. 畫面同時提供 `Google` / `Apple` / `LINE` 三個 OAuth 按鈕。
3. 帳密登入會呼叫 `/api/auth/login`，註冊會呼叫 `/api/auth/register`。
4. OAuth 登入會先呼叫 `POST /api/auth/oauth/{provider}/begin`，取得 `transactionId` 與 `authorizationUrl`。
5. Client 開啟瀏覽器後，持續輪詢 `POST /api/auth/oauth/exchange`。
6. 若狀態為 `authenticated`，直接保存 `authTokens` 並進入 bootstrap。
7. 若狀態為 `needs_profile_name`，切換成首次命名模式，送出 `POST /api/auth/oauth/complete-profile`。
8. 若狀態為 `conflict_existing_account_requires_bind`，提示玩家先登入既有帳號，再到設定中心進行綁定。
9. 若狀態為 `cancelled` 或 `failed`，畫面保留原登入頁並顯示對應訊息。
10. 任何登入成功後，都會呼叫 `/api/auth/bootstrap` 取得玩家啟動快照。

## OAuth 狀態與 UX

- `pending`
  - 顯示等待授權中的提示。
- `authenticated`
  - 直接建立 session，進入 bootstrap。
- `needs_profile_name`
  - 玩家需輸入 `playerName` 才會建立新帳號。
- `conflict_existing_account_requires_bind`
  - 不自動合併帳號，提示改用既有帳號登入後再綁定。
- `cancelled`
  - 視為中性提示，不當成系統錯誤。
- `failed`
  - 顯示 provider 授權失敗訊息，玩家可重新嘗試。

## Bootstrap / Settings Contract

`GET /api/auth/bootstrap` 與 `GET /api/profile/me` 都會回傳設定中心需要的帳號欄位：

- `account`
- `displayName`
- `playerPublicId`
- `playerName`
- `avatarId`
- `bio`
- `birthday`
- `genderType`
- `region`
- `linkedProviders`
- `passwordLoginEnabled`

登入成功後，Client 會把資料寫入 `GameState.player_data`，設定中心先吃本地快照，再補抓 `GET /api/profile/me`。

## 設定中心 OAuth 管理

`ConfigScene` 的帳號區塊包含：

- 帳號識別資訊
- `Google` / `Apple` / `LINE` 三張 provider 卡片
- 目前登入方式
- 安全登出按鈕

provider 卡片規則：

- 若 provider 已存在於 `linkedProviders`，顯示 `已綁定`
- 若 provider 不存在於 `linkedProviders`，顯示 `未綁定`
- 綁定中的 provider 會顯示處理中提示
- 若該 provider 是當前 session 的登入方式，顯示 `目前登入中`
- 若帳號沒有密碼登入，且只剩最後一個 OAuth 綁定，不允許解除綁定

設定中心 API：

- `POST /api/profile/oauth/{provider}/begin-link`
- `POST /api/profile/oauth/link/exchange`
- `DELETE /api/profile/oauth/{provider}`

解除綁定規則：

- 若解除的是目前 session 使用的登入方式，後端會撤銷當前 refresh token
- client 收到成功後會立即清除本地 session，並回到登入頁
- 若解除的不是目前登入方式，只更新 `linkedProviders`

## 多裝置登入行為

- refresh token 仍沿用既有策略
- 同 `userId + deviceId` 新登入會覆蓋同裝置舊 refresh token
- 不同裝置的登入 session 可以共存
- `currentLoginMethod` 僅表示目前這個 session 的登入方式

## 帳號恢復與營運可觀測性

- 第三方帳號主體以 provider subject 為唯一識別，不依 email 合併
- 若 provider 回傳 email，僅用於衝突檢查，不用來自動綁帳號
- 後端會保存 `passwordLoginEnabled` 與 `linkedProviders`
- OAuth 相關 begin / callback / exchange / complete-profile / link / unlink 都有 audit log

## 目前平台行為

- Web：以瀏覽器授權頁 + transaction 輪詢完成登入
- Android / iOS：目前同樣採瀏覽器授權頁 + transaction 輪詢，玩家完成授權後回到遊戲即可繼續流程
- 本版尚未加入原生 deep link bridge，因此 mobile 屬於可用的 browser-based 流程，而非原生 URL callback 整合

## Runtime API 設定

- 本機開發可用忽略版控的 `config/runtime_config.local.json` 覆蓋 API Base URL
- CI / GitHub Pages 會在 workflow 產生 `config/runtime_config.json`
- Client 啟動時優先讀 `runtime_config.local.json`，其次讀 `runtime_config.json`
