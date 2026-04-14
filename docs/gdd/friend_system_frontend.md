# Friend System — Frontend GDD (Godot)

## 1. Feature Summary

好友系統由一個主面板（FriendPanel）組成，包含三個分頁：
- **好友列表**：查看好友、送禮、管理展示貓咪
- **申請收件匣**：查看收到的申請並接受/拒絕
- **申請寄件匣**：查看已送出的申請並取消

---

## 2. Scene / Node 結構

```
FriendPanel (Control)
├── TabContainer
│   ├── FriendListTab
│   │   ├── TopBar
│   │   │   ├── FriendCountLabel       "好友 12 / 30"
│   │   │   ├── SendGiftAllButton      "🎁 一鍵送禮" / "今日已送出"
│   │   │   └── AddFriendButton        "＋ 加好友"
│   │   └── FriendScrollContainer
│   │       └── FriendList (VBoxContainer)
│   │           └── [FriendEntry] × N
│   │
│   ├── InboxTab  (收件匣)
│   │   ├── InboxBadgeLabel            收件數紅點
│   │   └── InboxScrollContainer
│   │       └── InboxList (VBoxContainer)
│   │           └── [RequestEntry] × N
│   │
│   └── OutboxTab (寄件匣)
│       └── OutboxScrollContainer
│           └── OutboxList (VBoxContainer)
│               └── [RequestEntry] × N
│
├── AddFriendDialog (PopupPanel)
│   ├── PlayerUidInput (LineEdit)      "輸入對方 UID"
│   ├── ConfirmButton                  "送出申請"
│   └── ErrorLabel
│
└── ShowcaseCatDialog (PopupPanel)
    ├── TitleLabel                     "選擇展示貓咪"
    ├── ClearButton                    "清除展示"
    ├── CatGridContainer
    │   └── [CatSelectItem] × N
    └── CloseButton
```

---

## 3. Sub-scene 規格

### 3.1 FriendEntry

顯示單一好友資訊的列表項目。

```
FriendEntry (HBoxContainer)
├── AvatarTexture (TextureRect)        頭像圖
├── InfoVBox (VBoxContainer)
│   ├── NameLabel                      DisplayName
│   ├── ActiveStatusLabel              "今天" / "3 天前" / "超過 30 天未登入"
│   │                                  顏色：綠色/黃色/灰色
│   └── ShowcaseCatHBox (HBoxContainer)
│       ├── CatThumbTexture            展示貓咪縮圖（無則隱藏）
│       └── CatInfoLabel               "Thunder Paws  Lv.10  ★★★"（無則隱藏）
└── ActionHBox (HBoxContainer)
    ├── ShowcaseButton  "設定展示"      → 開啟 ShowcaseCatDialog
    └── RemoveButton    "刪除"          → 確認 Dialog → DELETE /api/friend/{id}
```

### 3.2 RequestEntry（收件匣 / 寄件匣共用）

```
RequestEntry (HBoxContainer)
├── AvatarTexture
├── InfoVBox
│   ├── NameLabel
│   └── TimeLabel     "3 分鐘前" / "2 小時前" / "N 天前"
└── ActionHBox
    ├── [收件匣] AcceptButton "接受"  + RejectButton "拒絕"
    └── [寄件匣] CancelButton "取消申請"
```

---

## 4. User Flows

### 4.1 開啟好友面板

```
進入好友面板
  → GET /api/friend
  → GET /api/friend/request/inbox
  渲染 FriendListTab（含 HasSentGiftToday 狀態）
  渲染 InboxTab（顯示收件數紅點）
```

### 4.2 一鍵送禮

```
點擊 SendGiftAllButton
  → 若 HasSentGiftToday = true → 按鈕 disabled，顯示 "今日已送出"
  → 若 = false：
      顯示確認 Dialog："確定要送禮給 {friendCount} 位好友嗎？"
        → 確定 → POST /api/friend/gift/send-all
            成功 → Toast "已送禮給 {recipientCount} 位好友！"
                   HasSentGiftToday = true，按鈕變灰
            失敗 (GIFT_ALREADY_SENT) → Toast "今日已送出過"
```

### 4.3 加好友

```
點擊 AddFriendButton
  → 開啟 AddFriendDialog
  → 輸入 PlayerUid → 點擊 "送出申請"
      → POST /api/friend/request { receiverPlayerUid }
          成功 → Dialog 關閉，Toast "申請已送出"
                 自動刷新 OutboxTab
          失敗 → 在 Dialog 內顯示對應錯誤訊息：

| Error Code | 顯示文字 |
|---|---|
| FRIEND.USER_NOT_FOUND | 找不到該 UID 的玩家 |
| FRIEND.ALREADY_FRIENDS | 你們已經是好友了 |
| FRIEND.REQUEST_ALREADY_SENT | 已有待確認的申請 |
| FRIEND.REQUESTER_FULL | 你的好友已達上限 (30) |
| FRIEND.RECEIVER_FULL | 對方的好友已達上限 |
| FRIEND.REJECTED_COOLDOWN | 請稍後再試（顯示剩餘秒數倒數） |
| FRIEND.SELF_REQUEST | 不能加自己為好友 |
```

### 4.4 接受申請

```
點擊 AcceptButton
  → POST /api/friend/request/{requestId}/accept
      成功 → 從 InboxList 移除該項目，InboxBadge -1
             FriendCountLabel +1
             Toast "已接受好友申請"
      失敗 (RECEIVER_FULL) → Toast "你的好友已達上限，請先刪除好友"
      失敗 (REQUESTER_FULL) → Toast "對方好友已達上限，無法接受"
      失敗 (REQUEST_NOT_PENDING) → Toast "此申請已失效"，刷新 InboxList
```

### 4.5 拒絕申請

```
點擊 RejectButton
  → POST /api/friend/request/{requestId}/reject
      成功 → 從 InboxList 移除，InboxBadge -1
```

### 4.6 取消申請

```
點擊 CancelButton
  → DELETE /api/friend/request/{requestId}
      成功 → 從 OutboxList 移除
```

### 4.7 刪除好友

```
點擊 RemoveButton
  → 確認 Dialog："確定要刪除 {DisplayName} 嗎？"
      → 確定 → DELETE /api/friend/{friendUserId}
          成功 → 從 FriendList 移除，FriendCountLabel -1
                 Toast "已刪除好友"
```

### 4.8 設定展示貓咪

```
點擊 ShowcaseButton（位於 FriendEntry 上）
  → 開啟 ShowcaseCatDialog
      → 顯示所有 IsOwned=true 的貓咪（從 Config Cache 或現有 Cat API 取）
      → 點擊某隻貓 → PUT /api/friend/showcase-cat { playerCatId: X }
          成功 → 刷新該好友列表項目的展示貓咪資訊
                 Dialog 關閉
      → 點擊 "清除展示" → PUT /api/friend/showcase-cat { playerCatId: null }
          成功 → 展示貓咪區塊隱藏
```

---

## 5. UI States

### SendGiftAllButton 狀態

| 狀態 | 文字 | 顏色 | 可點擊 |
|------|------|------|--------|
| 可送出 | 🎁 一鍵送禮 | 正常 | 是 |
| 今日已送出 | ✓ 今日已送出 | 灰色 | 否 |
| 無好友 | 🎁 一鍵送禮 | 正常 | 是（recipientCount=0，送出後 Toast 提示） |

### ActiveStatusLabel 顏色

| daysAgo | 文字 | 顏色 |
|---------|------|------|
| 0 | 今天 | 綠色 |
| 1~7 | N 天前 | 黃色 |
| 8~30 | N 天前 | 橙色 |
| -1（>30天）| 超過 30 天未登入 | 灰色 |

### InboxTab 紅點

- 有未處理的 Pending 申請時顯示紅點數字
- 接受/拒絕後即時更新

---

## 6. API Calls Summary

| 時機 | Method | Endpoint |
|------|--------|----------|
| 開啟面板 | GET | `/api/friend` |
| 開啟面板 | GET | `/api/friend/request/inbox` |
| 切換到寄件匣 Tab | GET | `/api/friend/request/outbox` |
| 送出申請 | POST | `/api/friend/request` |
| 接受申請 | POST | `/api/friend/request/{id}/accept` |
| 拒絕申請 | POST | `/api/friend/request/{id}/reject` |
| 取消申請 | DELETE | `/api/friend/request/{id}` |
| 刪除好友 | DELETE | `/api/friend/{friendUserId}` |
| 一鍵送禮 | POST | `/api/friend/gift/send-all` |
| 設定/清除展示貓 | PUT | `/api/friend/showcase-cat` |

---

## 7. Navigation Entry Point

好友面板從主 HUD 的固定按鈕開啟（類似 Mail 面板的開啟方式）。  
建議在 HUD 加入 FriendButton，有待確認申請時顯示紅點提示。

紅點觸發條件：`inbox` 中有任何 status=Pending 的申請。  
紅點資料來源：在主 HUD 的定期輪詢或開啟面板時更新。

---

## 8. ShowcaseCat 展示說明

在好友的 FriendEntry 中，展示貓咪區塊顯示：
- 貓咪縮圖（ImagePath）
- 貓咪名稱（CatName）
- 等級（CatFoodLevel）
- 階級（Rank，以星星數顯示）
- 稀有度顏色外框（依 RarityType）

若好友未設定展示貓咪（ShowcaseCat = null），該區塊完全隱藏。

---

## 9. 注意事項

- **好友上限 30 人**：好友數到達上限時，AddFriendButton 仍可點擊（讓玩家看到提示而非按鈕消失），但 API 會回傳 `FRIEND.REQUESTER_FULL`。
- **ShowcaseCatDialog** 中的貓咪列表來源：可直接使用已有的貓咪 API 或 Config Cache，條件為 `IsOwned = true`。
- **好友屬性加成**為後端計算，前端無需特別顯示（除非設計上要在戰力面板顯示加成明細，目前不在本次範圍內）。
- **里程碑成就**整合現有成就系統，前端無需額外處理，透過 `/api/scooper/achievement` 自動顯示。
