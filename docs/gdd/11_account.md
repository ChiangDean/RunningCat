# 帳號系統

| 項目 | 說明 |
|------|------|
| MVP 登入方式 | 帳號密碼登入 |
| MVP 註冊方式 | 名稱 + 帳號 + 密碼 + 二次驗證密碼 |
| 登入入口 | `StartScene` |
| 驗證規則 | 帳號不可重複、密碼至少 8 碼、註冊時需再次輸入相同密碼 |
| 註冊成功後 | 直接取得 access token / refresh token，視同已登入 |

## StartScene 流程

1. 預設顯示帳號與密碼欄位。
2. 畫面提供 `登入` 與 `註冊` 兩個按鈕。
3. 按下 `登入` 時，前端呼叫 `/api/auth/login` 驗證帳號密碼。
4. 按下 `註冊` 後切換成註冊模式，補顯示名稱與再次輸入密碼欄位。
5. 註冊模式送出時，前端呼叫 `/api/auth/register` 建立帳號。
6. 成功後保存 token 與 API base URL，接著進入遊戲主流程。

## Runtime API 設定

- 本機開發可用忽略版控的 `config/runtime_config.local.json` 覆蓋 API Base URL。
- CI / GitHub Pages 部署會在 workflow 中根據 GitHub Environment 的 `API_BASE_URL` 自動產生 `config/runtime_config.json`。
- 若 GitHub 變數未包含 `/api`，workflow 會自動補上。
- Client 啟動時優先讀取 `config/runtime_config.local.json`，找不到才讀 `config/runtime_config.json`，最後才回退到內建 Local 預設值。
