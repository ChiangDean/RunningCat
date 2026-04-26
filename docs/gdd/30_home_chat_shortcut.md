# 30. 首頁聊天快捷入口

> Last updated: 2026-04-26

本文件補充主畫面 `BattleScene` 下方功能區新增的首頁聊天模式，定義它和既有完整聊天頁的分工、未讀提示與互動規則。

## 1. 目標

- 主畫面下方功能區原本提供 `鏟屎` 與 `衝撞` 兩種模式切換。
- 現在新增 `聊天` 模式，入口放在模式列左側，形成 `聊天 / 鏟屎 / 衝撞` 三段切換。
- 首頁聊天模式的定位是 compact chat：
  - 直接在首頁查看最近訊息
  - 直接切換 `全頻` / `隊伍`
  - 直接輸入與送出訊息
  - 保留原本 overlay 聊天頁作為完整聊天入口

## 2. 互動規則

### 2-1. 模式切換

- 點擊 `聊天` 後，下方區塊改為 compact chat 面板。
- 點擊 `鏟屎` 後，維持原本首頁鏟屎快捷入口。
- 點擊 `衝撞` 後，維持原本技能列 / 戰鬥資訊顯示。

### 2-2. Compact Chat 內容

- 上方提供 `全頻` 與 `隊伍` 分頁。
- 中段顯示目前頻道最近幾則訊息。
- 下方提供輸入框與送出按鈕。
- `全頻` 仍合併顯示 `system` 與 `world` 訊息。
- `隊伍` 頻道沒有可用 channel 時：
  - 仍可切換到隊伍頁籤
  - 顯示提示文案
  - 停用輸入與送出

### 2-3. 已讀與未讀

- 首頁 compact chat 使用和完整聊天頁相同的 `GameState` / realtime unread state。
- 只有在 compact chat 實際顯示時，才會把當前查看頻道標成已讀。
- `聊天` 模式按鈕需要顯示未讀紅點與數字。
- 原本更多功能中的聊天入口可保留未讀數提示，兩者共用同一份總未讀數。

## 3. 資料來源

- 訊息列表：`GameState` chat caches
- 未讀數：`GameState.chat_unread_counts`
- 發送訊息：`ApiClient.post_chat_message(...)`
- 已讀回報：`ChatRealtimeClient.mark_read(...)`

## 4. 實作位置

- 主畫面模式切換與按鈕紅點：`scripts/battle/battle_scene.gd`
- 首頁 compact chat 元件：`scripts/chat/HomeMiniChatPanel.gd`
- 版面定位模板：`scenes/ui/home/HomeBottomHudEditor.tscn`

## 5. 邊界

- 首頁聊天模式是快捷參與入口，不應取代完整聊天 overlay。
- 不要為首頁聊天再建立第二套訊息快取或未讀計數來源。
- 若未來調整首頁模式列版面，需保留 `聊天` 作為與 `鏟屎`、`衝撞` 同級的底部區塊切換模式。
