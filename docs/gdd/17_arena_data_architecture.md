# 17. 競技場資料架構（Arena API / Runtime Sync / 快取）

> Last updated: 2026-04-13

本文件說明競技場改為後端 API 驅動後，前端 `ArenaScene`、`ArenaBattleScene`、`GameState` 的資料流，以及目前和 Config 隊伍設定的銜接方式。

---

## 1. Local Cache

| 路徑 | 內容 |
| --- | --- |
| `user://config/arena.json` | 快取最新競技場總覽資料，包含玩家牌位、積分、競技券、賽季資訊、牌位獎勵與推薦對手。 |

競技場總覽屬於玩家即時狀態，但為了讓 `ArenaScene` 進入時可以先顯示上次成功資料，前端仍會保留 `user://config/arena.json` 作為本地快取。

---

## 2. Bootstrap Boundary

競技場總覽資料不放進 `GET /api/auth/bootstrap`。

原因：

1. 競技場資料在本地開發環境可能尚未 seed 完整。
2. 登入流程不應被競技場模組綁死。
3. 推薦對手屬於即時資料，進入 `ArenaScene` 時再拉取比較合理。

但競技場會依賴 bootstrap / config 快取提供的隊伍資料：

- `ArenaAttack`
- `ArenaDefense`
- `Boss`（作為攻擊隊伍 fallback）

---

## 3. API Contract

### 3.1 GET /api/arena

用途：取得競技場主頁需要的完整資料。

主要回傳欄位：

| 欄位 | 說明 |
| --- | --- |
| `playerPublicId` | 玩家公開 ID |
| `playerName` | 玩家名稱 |
| `score` / `highestScore` | 目前積分 / 最高積分 |
| `rankId` / `rankKey` / `rankName` | 目前牌位 |
| `tickets` | 競技券數量 |
| `seasonDisplayName` / `seasonEndDate` | 當前賽季資訊 |
| `ranks[]` | 牌位獎勵清單 |
| `opponents[]` | 推薦對手清單 |

`opponents[].defenseMembers[]` 目前會回傳：

- `catCatalogId`
- `catFoodLevel`
- `rank`

目前前端不依賴這個欄位顯示對手延遲。

### 3.2 POST /api/arena/opponents/{opponentId}/complete

用途：提交競技場戰鬥勝負並更新總覽。

Request body：

```json
{
  "isWin": true
}
```

---

## 4. Team Source Rules

### 4.1 攻擊隊伍

`ArenaScene` 按下挑戰時，會先決定本次競技場戰鬥要使用哪一組已確認隊伍：

1. 先讀 `ArenaAttack`
2. 若 `ArenaAttack` 沒有成員，fallback 到 `Boss`

前端 helper：`arena_scene_helpers.gd:get_effective_team_type()`

### 4.2 延遲同步

一旦決定有效隊伍類型後，`ArenaScene` 會呼叫：

`GameState.apply_active_team_from_config(teamType)`

這個步驟會一起同步：

- `GameState.player_team`
- `GameState.skill_delays`

因此 `ArenaBattleScene` 進場時，會直接讀到攻擊隊伍設定頁儲存的延遲。

### 4.3 防守隊伍

`ArenaDefense` 目前也支援在 Config 頁設定並儲存 `initialDelaySeconds`。

但目前 client 端沒有本地的防守戰鬥入口，因此：

- 設定頁與 API 契約都會保存防守延遲
- 本地前端目前不會自己消耗這份防守延遲資料
- 這份資料主要提供後端配對 / 對手資料 / 未來防守模擬使用

---

## 5. Runtime Flow

```text
ArenaScene open
  -> read GameState.arena_overview_data / arena.json
  -> render cached overview
  -> GET /api/arena
  -> GameState.update_arena()
  -> refresh scene

ArenaScene reroll
  -> collect current opponent ids
  -> GET /api/arena?excludeOpponentIds=...
  -> GameState.update_arena()

ArenaScene challenge
  -> resolve effective team type (ArenaAttack first, Boss fallback)
  -> GameState.apply_active_team_from_config(teamType)
  -> GameState.arena_opponent = selected opponent
  -> change_scene_to_file(ArenaBattleScene)

ArenaBattleScene complete
  -> POST /api/arena/opponents/{opponentId}/complete
  -> GameState.update_arena(response.overview)
```

---

## 6. Related Files

| 路徑 | 職責 |
| --- | --- |
| `scripts/arenaScene/ArenaScene.gd` | 主場景、挑戰入口、總覽刷新 |
| `scripts/arenaScene/arena_scene_helpers.gd` | 攻擊隊伍 fallback 與共用格式化 |
| `scripts/battle/arena_battle_scene.gd` | 競技場攻擊戰鬥 |
| `scripts/gamestate/GameState.gd` | 競技場總覽快取與有效隊伍套用 |
| `docs/gdd/15_config_data_architecture.md` | Config 與隊伍設定資料流 |
