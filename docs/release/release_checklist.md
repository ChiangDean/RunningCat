# MeowPartyDash Release Checklist

更新日期：2026-04-23

目前策略：先準備 `demo 版` 上架，不接正式金流；等 Google / Apple 開發者帳號申請完成後，再補 `Google Play Billing` / `Apple In-App Purchase`。

## P0 必做

### 1. 發版技術
- [x] 遊戲名稱統一為 `喵喵衝撞派對` / `Meow Party Dash!`
- [x] 補上 runtime config helper，支援 release feature flags
- [x] `feature_flags.oauth_enabled` 可在 demo 版關閉 OAuth 入口
- [x] 本地 demo 設定檔 `runtime_config.local.json` 已關閉 OAuth
- [x] 已產出 demo 用 App icon 素材（1024 / 512 / 256 / 192 / 180 / 152）
- [ ] 補齊 Android export preset、package name、version code、keystore
- [ ] 補齊 iOS export preset、bundle id、signing、provisioning
- [ ] 補齊正式 mobile API base URL 與 production / sandbox config
- [ ] 補齊自動化 build / release 流程

### 2. 付費與商店政策
- [x] 先採用 `跳過正式金流` 的 demo 策略
- [x] client 已支援 `feature_flags.paid_shop_enabled`
- [x] demo / local config 已預設 `paid_shop_enabled = false`
- [x] demo 版會隱藏付費商店入口
  - 隱藏 `衝撞幣商店` tab
  - 隱藏 `點數禮包` tab
  - 隱藏所有以 `TrapPoints` 作為付款幣別的 bundle
- [x] backend 已支援 `Shop:PaidShopEnabled`
- [x] API 預設 `Shop:PaidShopEnabled = false`
- [x] backend 會拒絕 `POST /api/shop/trap-points/purchase`
- [x] backend 會拒絕所有以 `TrapPoints` 作為付款幣別的 bundle 購買
- [x] backend shop overview 會隱藏以 `TrapPoints` 作為付款幣別的 bundle
- [ ] 正式接入 `Google Play Billing`
- [ ] 正式接入 `Apple In-App Purchase`
- [ ] 補 receipt / purchase token 驗證、補單、重複發貨防護、訂單紀錄
- [ ] 建立商店商品、merchant / payments profile、sandbox / test 帳號

### 3. 帳號、登入與法規
- [x] demo 版先隱藏 OAuth 入口，避免 iOS / Apple OAuth 未就緒阻塞上架 demo
- [x] `ConfigScene` 已補支援與法規卡片骨架
- [x] runtime config 已支援 `support_email` / `support_url` / `privacy_policy_url` / `account_deletion_url`
- [x] app 內已補刪除帳號入口
- [x] backend 已補 `DELETE /api/profile/me` soft delete
- [x] backend 已補 active-user middleware，刪帳後舊 session 會被擋下
- [x] 已補隱私政策 URL
- [x] 已補帳號刪除流程（app 內入口 + web 入口 + 後端處理）
- [x] 已補官方網站 / 支援頁 URL（GitHub Pages）
- [ ] 補正式 support email
- [ ] Apple production OAuth 參數補齊
- [ ] iOS OAuth UX 改為 deep link / universal link / custom URL scheme

### 4. 內容完成度
- [x] `Local / DEV` 保留未完成內容入口，`Sandbox / Production` 自動隱藏
- [x] 已清掉 reviewer 會直接碰到的 placeholder / 半成品入口（目前先隱藏 `活動 > 限時活動`）
- [ ] 補齊必要素材與 fallback，避免缺圖或空資料

### 5. 商店素材與提審資料
- [ ] 準備 Play / App Store 截圖、宣傳圖、短描述、完整描述
- [ ] 填寫 Google Play `Data safety`
- [ ] 填寫 Apple `App Privacy`
- [ ] 準備年齡分級資料
- [ ] 準備 reviewer / test account 與審核說明

### 6. 提審前驗收
- [ ] Android 真機 smoke test
- [ ] iPhone / iPad 真機 smoke test
- [ ] 驗證安裝、登入、主流程、斷線重連、背景切回、更新覆蓋安裝
- [ ] Google Play 新帳號若需要，先跑 closed test
- [ ] 確認 target API、iOS SDK、Xcode 版本符合當前要求

## 這次已完成的實作
- `MeowPartyDashClient/scripts/gamestate/RuntimeConfig.gd`
  - 新增 `paid_shop_enabled` feature flag
- `MeowPartyDashClient/scripts/ActivityScene.gd`
  - `Local / DEV` 保留 `限時活動` 入口，`Sandbox / Production` 自動隱藏
- `MeowPartyDashClient/.github/workflows/deploy-*.yml`
  - deploy 生成的 `runtime_config.json` 現在會寫入明確 `environment`
- `MeowPartyDashClient/scripts/shop/ShopScene.gd`
  - demo 版隱藏付費商店入口與 trap-point bundle
- `MeowPartyDashClient/config/runtime_config*.json`
  - demo / local config 預設關閉 paid shop
- `MeowPartyDashAPI/MeowPartyDashAPI.Infrastructure/Shop/ShopOptions.cs`
  - 新增 `Shop:PaidShopEnabled`
- `MeowPartyDashAPI/MeowPartyDashAPI.Application/Services/Shop/ShopService.cs`
  - paid shop 關閉時拒絕暫時金流與 trap-point bundle
- `MeowPartyDashAPI/appsettings*.json`
  - 預設關閉 paid shop

## 目前最務實的下一步
1. 先完成 Android demo 匯出與 closed test。
2. 同步補齊隱私政策、帳號刪除頁、support 聯絡方式。
3. 開發者帳號核准後，再接正式 Billing / IAP。
