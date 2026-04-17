# 帳號系統

| 項目 | 說明 |
| --- | --- |
| MVP 登入方式 | 帳號密碼登入 |
| MVP 註冊方式 | 暱稱 + 帳號 + 密碼 + 二次驗證密碼 |
| 登入入口 | `StartScene` |
| 角色資料入口 | 首頁左上角頭像 / 名稱區塊，開啟 `ConfigScene` 設定中心 |
| OAuth 狀態展示 | 設定中心顯示 Google / Apple 綁定狀態，但本期不做真正授權流程 |
| 登出入口 | 目前仍保留在 `StartScene` 的 session 按鈕 |

## StartScene 流程

1. 預設顯示帳號與密碼欄位。
2. 畫面提供 `登入` 與 `註冊` 兩個按鈕。
3. 按下 `登入` 時，前端呼叫 `/api/auth/login` 驗證帳號密碼。
4. 按下 `註冊` 後切換成註冊模式，補顯示暱稱與再次輸入密碼欄位。
5. 註冊模式送出時，前端呼叫 `/api/auth/register` 建立帳號。
6. 成功後先保存 token 與 API base URL，接著呼叫 `/api/auth/bootstrap` 取得玩家啟動快照。
7. bootstrap 成功後，`GameState.apply_player_bootstrap(...)` 會把登入 session、玩家資料、隊伍快取、商店 / 扭蛋 / 鏟屎官資料與設定中心需要的角色資料寫進 `user://`。
8. Client 重啟時若本地仍有 session，會先嘗試自動恢復登入；若 access token 過期，會用 refresh token 更新後再重新抓 bootstrap。
9. 玩家若從 `StartScene` 登出，Client 會優先呼叫 `/api/auth/revoke` 撤銷目前 refresh token；若 access token 已過期，會先 refresh 再 revoke，最後清除本機登入狀態與玩家快取。

## Bootstrap / Settings Contract

`GET /api/auth/bootstrap` 目前除了既有核心資料外，也會帶回設定中心首頁所需欄位：

- `account`
- `displayName`
- `playerName`
- `avatarId`
- `bio`
- `birthday`
- `genderType`
- `region`
- `linkedProviders`
- `playerPublicId`

Client 行為：

- 進入遊戲主流程後，首頁 HUD 直接使用 bootstrap 寫入的 `GameState.player_data`。
- 開啟 `ConfigScene` 時，先用本地快取立即繪製，再額外呼叫 `GET /api/profile/me` 拉最新資料。
- 玩家在設定中心按下儲存時，client 送 `PUT /api/profile/me`，成功後立即覆蓋 `GameState.player_data`，並刷新首頁左上角頭像與名稱。

## 設定中心相關 API

### `GET /api/profile/me`

用途：

- 取得最新角色資料與帳號綁定狀態。

重要欄位：

- `displayName`
- `playerName`
- `avatarId`
- `bio`
- `birthday`
- `genderType`
- `region`
- `account`
- `playerPublicId`
- `linkedProviders`

### `PUT /api/profile/me`

用途：

- 更新設定中心的角色資料。

目前 client 會送出的欄位：

- `displayName`
- `playerName`
- `avatarId`
- `bio`
- `birthday`
- `genderType`
- `region`

### `POST /api/redeem-codes/redeem`

用途：

- 設定中心帳號區塊的兌換碼功能。

成功後 client 會：

- 套用 `walletSnapshot` 到 `GameState`
- 清空輸入框
- 顯示獎勵 Dialog
- 額外顯示成功 Toast

## OAuth 狀態展示規則

- 設定中心只顯示 `Google` 與 `Apple` 兩張 provider 卡片。
- 狀態來源是 `linkedProviders`，不是 client 端自行推測。
- 若 provider 已存在於 `linkedProviders`，顯示 `已綁定`。
- 若不存在，顯示 `即將開放`，按鈕保持 disabled。
- 本期不做真正的 OAuth 授權、callback、token 換發與帳號綁定寫入。

## Runtime API 設定

- 本機開發可用忽略版控的 `config/runtime_config.local.json` 覆蓋 API Base URL。
- CI / GitHub Pages 部署會在 workflow 中根據 GitHub Environment 的 `API_BASE_URL` 自動產生 `config/runtime_config.json`。
- 若 GitHub 變數未包含 `/api`，workflow 會自動補上。
- Client 啟動時優先讀取 `config/runtime_config.local.json`，找不到才讀 `config/runtime_config.json`，最後才回退到內建 Local 預設值。
