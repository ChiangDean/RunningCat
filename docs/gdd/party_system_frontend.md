# Party System — Frontend GDD (Godot)

> Update 2026-04-19:
> The party surface now uses three shared bottom submenu sections: `overview`, `pending invites`, and `pending reviews`.
> `pending invites` is role-aware: players without a party see invites they received, while players already in a party see outgoing invites that are still waiting for the target player's response.
> `pending reviews` is also role-aware: players without a party see their own pending join applications, leaders can accept or reject join applications to the party, and regular members can only read that list.

## 1. Feature Summary

隊伍系統由主面板（PartyPanel）組成，根據玩家是否有隊伍顯示不同內容：

- **無隊伍狀態**：搜尋加入 / 建立新隊伍
- **有隊伍狀態**：
  - 隊伍資訊（隊名、成員列表）
  - 加油打氣功能
  - 隊伍頻道聊天（複用現有 ChatScene）
  - 隊長：管理申請、踢人、改名、轉讓、解散
  - 隊員：離隊、篡位（條件達成時）

---

## 2. Scene / Node 結構

```
PartyPanel (Control)
├── NoPartyView (Control)                       玩家無隊伍時顯示
│   ├── CreatePartyButton       "建立新隊伍"
│   ├── SearchPartyButton       "搜尋隊伍加入"
│   └── MyApplicationsButton   "我的申請記錄"
│
├── InPartyView (Control)                       玩家有隊伍時顯示
│   ├── PartyHeader (HBoxContainer)
│   │   ├── PartyNameLabel                      "喵喵隊"
│   │   ├── EditNameButton      [隊長限定] "✏ 改隊名"
│   │   ├── ChatButton          "💬"           → 開啟隊伍頻道聊天
│   │   └── UsurpButton         [篡位條件達成] "⚔ 申請篡位"
│   │
│   ├── MemberListContainer (VBoxContainer)
│   │   └── [PartyMemberEntry] × N (最多 5 筆)
│   │
│   ├── CheerSection (VBoxContainer)
│   │   ├── CheerSectionTitle   "今日加油打氣"
│   │   ├── FreeCheerButton     "免費加油打氣" / "✓ 已加油"
│   │   └── AdCheerButton       "看廣告再加油" / "✓ 已使用廣告"
│   │
│   ├── CouponSection (HBoxContainer)
│   │   ├── CouponCountLabel    "一小時收益券 × N"
│   │   └── UseCouponButton     "使用"
│   │
│   └── LeaderActionsSection (VBoxContainer)  [隊長限定]
│       ├── ApplicationsBadgeButton "審核申請 (N)"
│       ├── TransferLeaderButton    "轉讓隊長"
│       └── DisbandPartyButton      "解散隊伍"
│
├── CreatePartyDialog (PopupPanel)
│   ├── TitleLabel              "建立新隊伍"
│   ├── NameInput (LineEdit)    "輸入隊名（最多 30 字）"
│   ├── ConfirmButton           "建立"
│   └── ErrorLabel
│
├── SearchPartyDialog (PopupPanel)
│   ├── TitleLabel              "搜尋並加入隊伍"
│   ├── SearchInput (LineEdit)  "輸入隊伍 ID 或隊名"
│   ├── SearchButton            "搜尋"
│   ├── SearchResultContainer
│   │   └── SearchResultEntry
│   │       ├── PartyInfoLabel  "喵喵隊（3/5）"
│   │       └── ApplyButton     "申請加入"
│   └── ErrorLabel
│
├── ApplicationsDialog (PopupPanel)          隊長審核 / 玩家自己的申請
│   ├── TabContainer
│   │   ├── PendingTab  "待審核"
│   │   │   └── [ApplicationEntry] × N
│   │   └── MyApplicationTab  "我的申請"               [僅無隊伍時顯示]
│   │       └── [MyApplicationEntry] × N
│   └── CloseButton
│
├── EditNameDialog (PopupPanel)
│   ├── NameInput (LineEdit)
│   ├── ConfirmButton           "儲存"
│   └── ErrorLabel
│
├── InvitePlayerDialog (PopupPanel)          隊長 / 隊員可用
│   ├── PlayerNameInput (LineEdit) "輸入對方遊戲名稱"
│   ├── ConfirmButton            "確認"
│   ├── SearchStatusLabel
│   └── InviteCandidateList
│       └── InviteCandidateEntry × N
│           ├── Avatar
│           ├── PlayerNameLabel
│           ├── ScooperLevelLabel  "鏟屎官 Lv.X"
│           ├── PlayerUidLabel     "UID player_xxx"
│           ├── LastLoginLabel     "最後上線：5 分鐘前"
│           └── InviteButton       "邀請"
│
└── UseCouponConfirmDialog (PopupPanel)
    ├── InfoLabel               "使用後可獲得當前一小時收益（約 X 金幣）"
    ├── ConfirmButton           "確認使用"
    └── CancelButton            "取消"
```

---

## 3. Sub-scene 規格

### 3.1 PartyMemberEntry

```
PartyMemberEntry (HBoxContainer)
├── AvatarTexture (TextureRect)         頭像
├── InfoVBox (VBoxContainer)
│   ├── NameLabel                       DisplayName
│   └── RoleLabel                       "隊長" / "隊員"（顏色區分）
├── CheerStatusIcon                     若此人今天已對我加油打氣 → 顯示愛心 icon
└── ActionHBox (HBoxContainer)
    ├── InviteButton  [自己是隊長或隊員] → 開啟 InvitePlayerDialog（預填名稱為空）
    └── KickButton    [隊長限定]         → 確認 Dialog → POST kick
```

### 3.2 ApplicationEntry（隊長審核用）

```
ApplicationEntry (HBoxContainer)
├── AvatarTexture
├── InfoVBox
│   ├── NameLabel                       ApplicantDisplayName
│   ├── TypeLabel                       "玩家申請" / "隊員邀請"
│   └── TimeLabel                       "3 分鐘前"
└── ActionHBox
    ├── AcceptButton  "接受"
    └── RejectButton  "拒絕"
```

### 3.3 MyApplicationEntry（自己的申請記錄）

```
MyApplicationEntry (HBoxContainer)
├── InfoVBox
│   ├── PartyNameLabel                  申請的隊伍名稱
│   └── StatusLabel                     "待確認" / "已接受" / "已拒絕"
└── CancelButton  "取消"  [Status = Pending 時顯示]
```

---

## 4. User Flows

### 4.1 開啟隊伍面板

```
進入 PartyPanel
  → GET /api/party/my
      成功（有隊伍） → 顯示 InPartyView
                       初始化成員列表、加油狀態
                       GET /api/party/{partyId}/cheer → 渲染加油打氣狀態
      失敗 PARTY.NOT_IN_PARTY → 顯示 NoPartyView
```

---

### 4.2 建立隊伍

```
點擊 CreatePartyButton
  → 開啟 CreatePartyDialog
  → 輸入隊名 → 點擊 "建立"
      → POST /api/party { name }
          成功 → Dialog 關閉
                 切換到 InPartyView，渲染新隊伍
                 Toast "隊伍「{name}」已建立！"
          失敗：

| Error Code | 顯示文字 |
|---|---|
| PARTY.ALREADY_IN_PARTY | 你已有隊伍 |
| PARTY.NAME_TAKEN | 此隊名已被使用 |
| PARTY.NAME_INVALID | 隊名不合規，請重新輸入 |
```

---

### 4.3 搜尋並申請加入

```
點擊 SearchPartyButton
  → 開啟 SearchPartyDialog
  → 輸入隊伍 ID 或隊名 → 點擊 "搜尋"
      → GET /api/party/{id 或 by name}
          顯示搜尋結果（隊名、目前人數）
      → 點擊 "申請加入"
          → POST /api/party/apply { partyId }
              成功 → Toast "申請已送出，等待隊長確認"
                     Dialog 關閉
              失敗：

| Error Code | 顯示文字 |
|---|---|
| PARTY.ALREADY_IN_PARTY | 你已有隊伍 |
| PARTY.NOT_FOUND | 找不到此隊伍 |
| PARTY.FULL | 隊伍已滿 |
| PARTY.APPLICATION_EXISTS | 已有待確認的申請 |
```

---

### 4.4 加油打氣（免費）

```
點擊 FreeCheerButton
  → 若 HasCheeredFree = true → 按鈕已 disabled，不可點擊
  → 若 = false：
      → POST /api/party/{partyId}/cheer { isAdBoost: false }
          成功 → FreeCheerButton → 灰色 "✓ 已加油"
                 Toast "加油打氣完成！獲得 1 張一小時收益券"
                 CouponCountLabel +1
                 刷新 CheerStatusResponse（隊友狀態）
```

---

### 4.5 加油打氣（廣告）

```
點擊 AdCheerButton
  → 若 HasCheeredAd = true → 按鈕已 disabled
  → 若 = false：
      顯示第一次確認 Dialog："確定要透過廣告獲得一次額外加油打氣機會嗎？"
          → 確定 → 顯示第二次提示 Dialog："（廣告播放模擬中）點擊確認完成"
              → 確認 → POST /api/party/{partyId}/cheer { isAdBoost: true }
                  成功 → AdCheerButton → 灰色 "✓ 已使用廣告"
                         Toast "廣告加油打氣完成！獲得 1 張一小時收益券"
                         CouponCountLabel +1
```

---

### 4.6 使用收益券

```
點擊 UseCouponButton
  → 顯示 UseCouponConfirmDialog（顯示預估金幣數量）
      → 確認 → POST /api/party/cheer-coupon/use
          成功 → Dialog 關閉
                 Toast "獲得 {goldGranted} 金幣！"
                 CouponCountLabel -1
                 刷新貨幣顯示
          失敗 PARTY.NO_COUPON → Toast "無可用收益券"
```

---

### 4.7 審核申請（隊長）

```
點擊 ApplicationsBadgeButton
  → GET /api/party/{partyId}/applications
  → 開啟 ApplicationsDialog > PendingTab
  → 點擊 AcceptButton
      → POST /api/party/application/{id}/accept
          成功 → 從列表移除，Badge -1
                 刷新 MemberListContainer
                 Toast "已接受 {name} 的申請"
          失敗 PARTY.TARGET_IN_PARTY → Toast "對方已加入其他隊伍"
          失敗 PARTY.FULL            → Toast "隊伍已滿"
  → 點擊 RejectButton
      → POST /api/party/application/{id}/reject
          成功 → 從列表移除，Badge -1
```

---

### 4.8 邀請玩家

```
點擊 InviteButton（PartyMemberEntry 上方）或其他邀請入口
  → 開啟 InvitePlayerDialog
  → 輸入對方遊戲名稱 → 點擊 "確認"
      → GET /api/party/{partyId}/invite-candidates?query={playerName}
          顯示符合清單：
              頭像 / 玩家名稱 / 鏟屎官等級 / UID / 最後上線
          排序：最後上線時間越近越前面
      → 點擊候選列上的 "邀請"
          → POST /api/party/{partyId}/invite { targetPlayerUid }
              成功 → Toast "邀請已送出" 並關閉 Dialog
              失敗：

| Error Code | 顯示文字 |
|---|---|
| PARTY.TARGET_IN_PARTY | 對方已有隊伍 |
| PARTY.FULL | 隊伍已滿 |
| PARTY.APPLICATION_EXISTS | 對方已有待確認申請 |
| PARTY.TARGET_NOT_FOUND | 找不到此玩家 |
```

---

### 4.9 改隊名（隊長）

```
點擊 EditNameButton
  → 開啟 EditNameDialog（預填現有隊名）
  → 修改後點擊 "儲存"
      → PUT /api/party/{partyId}/name { name }
          成功 → PartyNameLabel 更新
                 Toast "隊名已更改為「{name}」"
                 Dialog 關閉
          失敗 PARTY.NAME_TAKEN → 顯示 "此隊名已被使用"
```

---

### 4.10 轉讓隊長（隊長）

```
點擊 TransferLeaderButton
  → 確認 Dialog："確定要轉讓隊長嗎？隊長將由加入時間最早的成員繼任。"
      → 確定 → POST /api/party/{partyId}/transfer-leadership
          成功 → 刷新 PartyDetailResponse
                 更新 RoleLabel
                 Toast "隊長已轉讓給 {newLeaderName}"
                 LeaderActionsSection 隱藏（自己已非隊長）
```

---

### 4.11 篡位（隊員）

```
UsurpButton 顯示條件：
  is_usurpation_eligible = true AND 自己不是隊長

點擊 UsurpButton
  → 確認 Dialog："確定要申請篡位嗎？你將立刻成為新隊長。"
      → 確定 → POST /api/party/{partyId}/usurp
          成功 → 刷新 PartyDetailResponse
                 Toast "你已成為新隊長！"
                 顯示 LeaderActionsSection
          失敗 PARTY.USURP_NOT_ELIGIBLE → Toast "篡位條件已失效（可能已被他人搶先）"
                                          刷新 PartyDetailResponse
```

---

### 4.12 離隊（隊員）

```
（隊員才能看到離隊選項，隊長看到的是轉讓隊長）

點擊 LeavePartyButton（建議放在次要操作區或更多選單中）
  → 確認 Dialog："確定要離開此隊伍嗎？"
      → 確定 → DELETE /api/party/{partyId}/leave
          成功 → 切換到 NoPartyView
                 Toast "你已離開隊伍"
          失敗 PARTY.LEADER_CANNOT_LEAVE → Toast "請先轉讓隊長才能離隊"
```

---

### 4.13 解散隊伍（隊長，僅剩一人時）

```
點擊 DisbandPartyButton
  → 確認 Dialog："確定要解散隊伍嗎？此操作不可復原。"
      → 確定 → DELETE /api/party/{partyId}
          成功 → 切換到 NoPartyView
                 Toast "隊伍已解散"
          失敗 PARTY.HAS_OTHER_MEMBERS → Toast "隊伍還有其他成員，無法解散"
```

---

### 4.14 踢除隊員（隊長）

```
點擊 KickButton（PartyMemberEntry 上）
  → 確認 Dialog："確定要踢除 {name} 嗎？"
      → 確定 → POST /api/party/{partyId}/kick/{targetUserId}
          成功 → 從 MemberListContainer 移除
                 Toast "{name} 已被踢除"
```

---

### 4.15 開啟隊伍聊天

```
點擊 ChatButton
  → 取得 PartyDetailResponse.ChatChannelKey（例如 "party:123"）
  → 開啟 ChatScene，channelKey = "party:123"
  （複用現有 ChatScene 的 channelKey 切換機制）
```

---

## 5. UI States

### FreeCheerButton 狀態

| 狀態 | 文字 | 顏色 | 可點擊 |
|------|------|------|--------|
| 可加油 | 免費加油打氣 | 正常 | 是 |
| 已加油 | ✓ 已加油 | 灰色 | 否 |

### AdCheerButton 狀態

| 狀態 | 文字 | 顏色 | 可點擊 |
|------|------|------|--------|
| 可用 | 看廣告再加油 | 正常 | 是 |
| 已使用 | ✓ 已使用廣告 | 灰色 | 否 |
| 免費未用完 | 請先使用免費加油 | 灰色 | 否 |

> AdCheerButton 需等 FreeCheerButton 已使用後才可點擊。

### UsurpButton 顯示條件

| 條件 | 是否顯示 |
|------|---------|
| `is_usurpation_eligible = true` AND `非隊長` | 顯示 |
| 其他 | 隱藏 |

### ApplicationsBadgeButton

- 有待確認申請時顯示數字紅點（`GetPendingApplicationsAsync` 回傳數量）
- 接受 / 拒絕後即時 -1

### DisbandPartyButton 顯示條件

- 僅在 `Members.Count == 1`（自己是唯一成員）時可見

### LeavePartyButton 顯示條件

- 僅隊員（非隊長）可見

---

## 6. API Calls Summary

| 時機 | Method | Endpoint |
|------|--------|----------|
| 開啟面板 | GET | `/api/party/my` |
| 加油狀態 | GET | `/api/party/{id}/cheer` |
| 建立隊伍 | POST | `/api/party` |
| 改隊名 | PUT | `/api/party/{id}/name` |
| 解散隊伍 | DELETE | `/api/party/{id}` |
| 轉讓隊長 | POST | `/api/party/{id}/transfer-leadership` |
| 踢除隊員 | POST | `/api/party/{id}/kick/{uid}` |
| 離隊 | DELETE | `/api/party/{id}/leave` |
| 申請加入 | POST | `/api/party/apply` |
| 搜尋邀請候選 | GET | `/api/party/{id}/invite-candidates?query={playerName}` |
| 邀請玩家 | POST | `/api/party/{id}/invite` |
| 取得待審核申請 | GET | `/api/party/{id}/applications` |
| 接受申請 | POST | `/api/party/application/{id}/accept` |
| 拒絕申請 | POST | `/api/party/application/{id}/reject` |
| 取消申請 | DELETE | `/api/party/application/{id}` |
| 篡位 | POST | `/api/party/{id}/usurp` |
| 免費加油打氣 | POST | `/api/party/{id}/cheer` (isAdBoost: false) |
| 廣告加油打氣 | POST | `/api/party/{id}/cheer` (isAdBoost: true) |
| 使用收益券 | POST | `/api/party/cheer-coupon/use` |

---

## 7. Navigation Entry Point

隊伍面板從主 HUD 的社交按鈕進入（與好友面板同一入口，改為分頁或子頁面）。

紅點觸發條件（隊長）：`ApplicationsBadgeButton` 中有 pending 申請。
Bootstrap 時同步取得紅點數量（透過 `PartyDetailResponse` 或獨立 badge endpoint）。

---

## 8. 注意事項

- **聊天整合**：`ChatScene` 複用現有實作，僅切換 `channelKey = "party:{partyId}"`，無需新增 scene。
- **加油打氣廣告**：目前尚未串接廣告 SDK，改用兩個連續確認 Dialog 模擬流程。廣告串接後直接替換第二個 Dialog 為廣告播放邏輯。
- **收益券數量顯示**：從 bootstrap 或 `/api/party/my` 中一併回傳，或呼叫現有消耗品庫存 API 取得。
- **隊伍聊天頻道 key**：格式為 `party:{partyId}`（例如 `party:42`），由後端 `PartyDetailResponse.ChatChannelKey` 提供。
- **篡位按鈕**：`is_usurpation_eligible` 在每日重置後才變更，前端以 `PartyDetailResponse` 中的值為準，不做額外輪詢。
- **加油上限 8 張**：上限由後端控管（pending_reward 寫入時檢查），前端無需額外顯示上限數字（除非設計上有需求）。
