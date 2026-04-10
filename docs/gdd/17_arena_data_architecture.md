# 17. 競技場資料架構（Arena API / Bootstrap / 快取）

> 最後更新：2026-04-11

本文件說明競技場改為後端 API 驅動後，前端 `ArenaScene`、`ArenaBattleScene`、`GameState` 的資料流。

---

## 快取位置

| 路徑 | 用途 |
| --- | --- |
| `user://config/arena.json` | 快取最新競技場總覽資料，包含玩家牌位、積分、競技券、賽季資訊、牌位獎勵與推薦對手。 |

競技場資料屬於玩家即時狀態，但為了讓 `ArenaScene` 進入時可以先顯示上次成功資料，本次採用 `user://config/arena.json` 做本地快取。

---

## Bootstrap

競技場資料不再放進 `GET /api/auth/bootstrap`。

原因：

1. 競技場資料表在本地開發環境可能尚未 seed 完整
2. 登入流程不應被競技場模組綁死
3. 推薦對手屬於即時資料，進入 `ArenaScene` 時再拉取比較合理

---

## API 一覽

### `GET /api/arena`

用途：取得競技場主頁需要的完整資料。

Query 參數：

| 參數 | 說明 |
| --- | --- |
| `excludeOpponentIds` | 可重複傳入多筆，用於重骰時排除目前畫面上的對手 ID。 |

回傳重點：

| 欄位 | 說明 |
| --- | --- |
| `playerPublicId` | 玩家公開 ID |
| `playerName` | 玩家名稱 |
| `score` / `highestScore` | 目前積分 / 最高積分 |
| `rankId` / `rankKey` / `rankName` | 目前牌位 |
| `tickets` | 目前競技券 |
| `dailyPurchaseCount` / `maxDailyPurchaseCount` | 今日已購買次數 / 每日上限 |
| `ticketsPerPurchase` / `ticketPurchaseCosts` | 每次購買張數 / 價格表 |
| `diamonds` / `trapCages` / `catFood` / `specialCatFood` | 競技場頁需要同步的資源快照 |
| `seasonDisplayName` / `seasonEndDate` | 賽季資訊 |
| `ranks[]` | 牌位獎勵清單與可領狀態 |
| `opponents[]` | 推薦對手列表 |

`opponents[]` 每筆資料包含：

| 欄位 | 說明 |
| --- | --- |
| `opponentId` | 對手識別碼。可能是真實玩家公開 ID，也可能是 `bot_*` 假想對手。 |
| `playerName` | 對手名稱 |
| `score` | 對手積分 |
| `rankName` | 對手牌位名稱 |
| `defenseMembers[]` | 防守隊伍成員，內含 `catCatalogId`、`catFoodLevel`、`rank` |

### `POST /api/arena/tickets/purchase`

用途：購買競技券。

回傳：

| 欄位 | 說明 |
| --- | --- |
| `cost` | 本次消耗鑽石 |
| `addedTickets` | 本次增加競技券 |
| `overview` | 更新後的 `ArenaOverviewResponse` |

### `POST /api/arena/rewards/{rankId}/claim`

用途：領取指定牌位獎勵。

回傳：

| 欄位 | 說明 |
| --- | --- |
| `rankId` / `rankName` | 本次領取的牌位 |
| `rewards[]` | 實際發放獎勵 |
| `overview` | 更新後的 `ArenaOverviewResponse` |

### `POST /api/arena/opponents/{opponentId}/complete`

用途：對戰結束後送出勝負結果，由後端結算積分與扣除競技券。

Request body：

```json
{
  "isWin": true
}
```

回傳：

| 欄位 | 說明 |
| --- | --- |
| `isWin` | 本次是否勝利 |
| `scoreDelta` | 積分變化 |
| `oldScore` / `newScore` | 結算前後積分 |
| `rankName` | 結算後牌位名稱 |
| `overview` | 更新後的 `ArenaOverviewResponse` |

---

## 前端資料流

```text
登入 / 啟動
    -> GET /api/auth/bootstrap
    -> GameState.apply_player_bootstrap()

ArenaScene 進入
    -> 先讀 GameState.arena_overview_data / arena.json
    -> 顯示上次快取
    -> GET /api/arena
    -> GameState.update_arena()
    -> 重新渲染畫面

ArenaScene 重骰
    -> 取出目前畫面的 opponents[].opponentId
    -> GET /api/arena?excludeOpponentIds=...
    -> GameState.update_arena()
    -> 更新畫面

購買競技券 / 領牌位獎勵
    -> ArenaScene 呼叫對應 API
    -> 取回 response.overview
    -> GameState.update_arena()
    -> 同步更新 player_data 資源

ArenaBattleScene 結束
    -> POST /api/arena/opponents/{opponentId}/complete
    -> GameState.update_arena(response.overview)
    -> 顯示結算結果
```

---

## 場景拆分

本次將競技場前端腳本拆到 `scripts/arenaScene/`：

| 檔案 | 職責 |
| --- | --- |
| `scripts/arenaScene/ArenaScene.gd` | 主場景、UI 建構、API 串接、畫面刷新 |
| `scripts/arenaScene/arena_scene_helpers.gd` | 隊伍名稱、獎勵文字、錯誤訊息等共用格式化邏輯 |
| `scripts/arenaScene/arena_scene_reward_popup.gd` | 牌位獎勵彈窗 |

`scenes/ArenaScene.tscn` 也已改為指向新的 `res://scripts/arenaScene/ArenaScene.gd`。
