# 喵喵衝撞派對 Release Checklist

Last updated: 2026-04-23

適用範圍：目前以 `demo / closed test` 上架準備為主。正式收費版在 `Google Play Billing`、`Apple In-App Purchase` 與商店帳號完成前，先不往前推。

## P0 必做

### 1. 發版技術

- [x] 遊戲名稱已對齊：`喵喵衝撞派對` / `Meow Party Dash!`
- [x] 已補 runtime config helper 與 release feature flag 流程
- [x] 已補 `feature_flags.oauth_enabled`，demo 版可完整隱藏 OAuth 入口
- [x] 已建立本地 demo 設定檔，方便 local 開發直接關閉 OAuth
- [x] 已產出 demo 版 App icon 素材
- [x] 已補 `environment` runtime config 流程，`Sandbox / Production` 不再誤判成 `Local`
- [ ] 補 Android export preset、package name、version code、keystore
- [ ] 補 iOS export preset、bundle id、signing、provisioning
- [ ] 補正式 mobile API base URL 與 production / sandbox config
- [ ] 補自動化 build / release 流程

### 2. 付費與商店政策

- [x] 已決定 demo 版先跳過正式金流
- [x] Client 已補 `feature_flags.paid_shop_enabled`
- [x] Demo / Local config 已預設 `paid_shop_enabled = false`
- [x] Demo 版已隱藏付費商店入口與 `TrapPoints` 付款 bundle
- [x] Backend 已補 `Shop:PaidShopEnabled`
- [x] API 已在 paid shop 關閉時拒絕 `trap-points/purchase`
- [x] API overview 已隱藏 trap-points 付費 bundle
- [ ] 正式接 `Google Play Billing`
- [ ] 正式接 `Apple In-App Purchase`
- [ ] 補 receipt / purchase token 驗證、補單、重複發貨防護
- [ ] 補 merchant / payments profile / sandbox 測試設定

### 3. 帳號、登入與法規

- [x] Demo 版已隱藏 OAuth 入口，先不依賴 iOS / Apple 開發者帳號
- [x] 設定中心已補 `支援 / 隱私政策 / 刪除帳號` 入口
- [x] Runtime config 已支援 `support_email`、`support_url`、`privacy_policy_url`、`account_deletion_url`
- [x] App 內已可發起刪帳流程
- [x] Backend 已補 `DELETE /api/profile/me` soft delete
- [x] Backend 已補 active-user session guard，已刪除帳號不再沿用舊 session
- [x] 已準備 GitHub Pages 版 `support / privacy / account-deletion` 靜態頁
- [ ] 補正式 support email
- [ ] 補 Apple production OAuth 設定
- [ ] iOS OAuth 改成 deep link / universal link / custom URL scheme 回跳流程

### 4. 內容完成度

- [x] `Local / DEV` 保留未完成內容；`Sandbox / Production` 會隱藏 reviewer 不該看到的入口
- [x] Reviewer 容易碰到的未完成活動入口已先隱藏
- [x] 已補 runtime fallback，缺圖時不再直接留白：
  - catalog icon
  - 商店 / 背包 / 郵件 / 競技場獎勵 icon
  - 常駐活動 / 地城 / Scooper preview 圖
  - 功能頁背景圖
- [ ] 正式素材仍需持續補齊，fallback 只能保底不能取代正式美術

### 5. 商店素材與提審資料

- [ ] 準備 Google Play / App Store 截圖、宣傳圖、商店 icon 主視覺
- [ ] 補商店短描述 / 完整描述 / 關鍵賣點
- [ ] 填 Google Play `Data safety`
- [ ] 填 Apple `App Privacy`
- [ ] 準備 reviewer / test account 與操作說明
- [ ] 準備年齡分級與商店 metadata

### 6. 提審前驗收

- [ ] Android 真機 smoke test
- [ ] iPhone / iPad 真機 smoke test
- [ ] 驗證登入、刪帳、背景切換、斷線重連、首次載入、低網速流程
- [ ] 跑 Google Play closed test
- [ ] 確認 target API、iOS SDK、Xcode / export toolchain 符合上架要求

## 可繼續由工程處理

- [ ] 補更多 repo 內 release 文件與提審文件
- [ ] 產商店文案草稿：短描述、完整描述、更新說明、審核備註
- [ ] 產 `Data safety` / `App Privacy` 初稿
- [ ] 補 Android demo export 骨架與版本號規則
- [ ] 補更多缺圖 fallback 與 placeholder 清理
- [ ] 整理 closed test / TestFlight 驗收清單
