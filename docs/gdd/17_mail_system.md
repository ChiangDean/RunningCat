# 郵件系統

## 17-1 目標

郵件系統第一版主要提供：

- 系統獎勵信箱
- 人工補發信箱
- 全服獎勵發放
- 單封領取與全部領取
- 主戰鬥頁郵件入口與紅點提示

本案產品決策：

- 所有系統獎勵統一走郵件，玩家手動領取
- 入口放主戰鬥頁
- 入口需顯示紅點
- 郵件支援資源型與精準實體型附件

---

## 17-2 現況分析

### 現有前端結構

- 登入後由 `StartScene` 呼叫 `/api/auth/bootstrap`
- 共用 API 呼叫集中在 `scripts/ApiClient.gd`
- 全域狀態集中在 `scripts/gamestate/GameState.gd`
- 主戰鬥首頁為 `BattleScene`
- 目前沒有郵件頁、郵件資料快取、郵件紅點邏輯

### 導入原則

郵件系統要沿用目前寫法：

- API 呼叫集中放在 `ApiClient.gd`
- 全域郵件摘要與快取放在 `GameState.gd`
- UI 仍用現有 Godot scene + script 模式，不額外導入新的 UI framework

---

## 17-3 入口與紅點

### 主入口

- 在主戰鬥頁新增常駐「郵件」按鈕
- 按鈕位置需避開核心戰鬥操作與既有導覽
- 按鈕按下後切到 `MailScene`

### 紅點顯示規則

顯示紅點當下列任一條件成立：

- 有未讀郵件
- 有可領取附件的郵件

### 紅點資料來源

優先順序：

1. 使用 bootstrap 回傳的 `mailSummary`
2. 場景切回首頁時呼叫 `GET /api/mail/summary`
3. 領取成功後以 API 回傳摘要即時更新

避免每次切首頁都拉完整郵件列表。

---

## 17-4 場景規劃

### `MailScene`

用途：

- 顯示郵件列表
- 顯示單封詳情
- 執行單封領取
- 執行全部領取

### 建議畫面區塊

#### 上方列

- 返回按鈕
- 標題 `郵件`
- `全部領取` 按鈕

#### 左側或上方列表區

每封郵件卡片顯示：

- 標題
- 郵件類型標籤
- 建立時間
- 到期時間
- 未讀標記
- 可領取標記

#### 詳情區

顯示：

- 標題
- 內文
- 附件列表
- 單封領取按鈕

### 手機優先

若以手機比例為主，建議採：

- 上半部郵件列表
- 下半部郵件詳情

或：

- 先列表
- 點入後切詳情頁

第一版建議採「單頁列表 + 下方詳情」以減少切頁複雜度。

---

## 17-5 郵件列表顯示規則

### 排序

1. 未領取
2. 未讀
3. 新到舊

### 卡片狀態

- 未讀：標題較亮、顯示藍點或角標
- 已讀未領：顯示「可領取」
- 已領：顯示「已領取」
- 已過期：顯示「已過期」，領取按鈕 disabled

### 清單分頁

第一版支援 API 分頁，但 UI 可先做簡單頁次載入或「載入更多」。

---

## 17-6 附件顯示規則

### 資源型附件

直接顯示：

- 圖示
- 名稱
- 數量

例如：

- 金幣 x1000
- 鑽石 x300
- 貓糧 x50

### 實體型附件

需顯示具體名稱：

- 貓咪名稱
- 裝備名稱
- 記憶名稱
- 寶物名稱
- 特殊能力名稱

前端不自行推導附件業務規則，應由 API 回傳已整理好的顯示資料：

- `displayName`
- `iconKey` 或 `imagePath`
- `quantity`
- `rewardType`
- `description`

---

## 17-7 玩家操作流程

### 進入郵件頁

1. 點擊主戰鬥頁郵件按鈕
2. 若本地沒有列表或快取過期，呼叫 `GET /api/mail`
3. 預設選中第一封郵件
4. 若該封未讀，背景送出 `POST /api/mail/{mailId}/read`
5. UI 同步清掉未讀標記與首頁紅點

### 單封領取

1. 玩家點擊單封領取
2. 呼叫 `POST /api/mail/{mailId}/claim`
3. 成功後更新：
   - 郵件狀態
   - GameState 核心資源
   - 紅點摘要
4. 顯示獎勵彈窗

### 全部領取

1. 玩家點擊 `全部領取`
2. 先跳 confirm dialog
3. 呼叫 `POST /api/mail/claim-all`
4. 成功後：
   - 批次更新列表狀態
   - 更新 GameState 核心資源
   - 更新紅點
   - 顯示彙總獎勵彈窗

---

## 17-8 GameState 規劃

第一版建議新增以下資料：

- `mail_summary_data: Dictionary`
- `mail_list_data: Array`
- `selected_mail_data: Dictionary`

### `mail_summary_data`

至少包含：

- `unreadCount`
- `claimableCount`
- `totalCount`

### GameState 更新時機

- bootstrap 成功後寫入 `mailSummary`
- 查詢 summary 後更新
- 查詢列表後更新 `mail_list_data`
- 單封領取 / 全領成功後同步更新

---

## 17-9 ApiClient 規劃

第一版建議新增：

- `get_mail_summary(callback)`
- `get_mail_list(callback, page := 1, page_size := 20)`
- `get_mail_detail(mail_id, callback)`
- `mark_mail_read(mail_id, callback)`
- `claim_mail(mail_id, callback)`
- `claim_all_mails(callback)`

所有郵件 API 仍沿用現有：

- bearer token
- 401 refresh retry
- 統一 envelope parsing

---

## 17-10 UI/UX 規則

### 按鈕狀態

- 已領取：disabled，顯示 `已領取`
- 已過期：disabled，顯示 `已過期`
- 無附件：不顯示領取按鈕

### 彈窗

沿用現有 `DialogManager`：

- 全部領取前 confirm
- 領取成功 info dialog
- API 錯誤 info dialog

### 首頁紅點刷新時機

- 登入 bootstrap 後
- 郵件頁返回首頁前
- 領取成功後
- 切回主戰鬥頁時可額外 refresh 一次 summary

---

## 17-11 與現有資料同步

由於目前 `GameState` 已持有核心資源：

- gold
- diamonds
- trap points
- cat food
- special cat food
- whisker shards
- memory shards
- poop count

所以 mail claim 成功後，後端應直接回傳最新關鍵資源快照，前端不要自行根據附件內容推算最終數值，避免與後端規則不一致。

---

## 17-12 第一版顯示建議

### 郵件類型顏色

- `System`：灰藍
- `Reward`：綠色
- `Compensation`：橘色
- `Event`：紫紅或亮色活動標
- `Purchase`：金色

### 紅點樣式

- 小紅圓點 + 白色數字
- 數字超過 99 顯示 `99+`

### 郵件按鈕文案

- 首頁入口：`郵件`
- 單封領取：`領取`
- 全部領取：`全部領取`

---

## 17-13 實作順序建議

1. 後端先完成 `mailSummary` 與玩家端 mail API
2. `ApiClient.gd` 補齊 mail 方法
3. `GameState.gd` 補齊郵件摘要與列表快取
4. `BattleScene` 加入口與紅點
5. 新增 `MailScene`
6. 補上單封領取與全部領取彈窗流程

---

## 17-14 驗收重點

- 首頁能看到郵件入口
- 有未讀或未領郵件時會顯示紅點
- 郵件列表可正確顯示未讀/未領/已領/過期
- 單封領取後核心資源即時更新
- 全部領取後列表與紅點即時更新
- API 401 refresh 後郵件頁仍能正常操作
