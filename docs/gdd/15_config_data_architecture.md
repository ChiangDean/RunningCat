# 15. Config Data Architecture

> Last updated: 2026-04-13

本文件記錄 `ConfigScene` 改為後端 API 驅動後的資料來源、前端 draft 行為、送出流程，以及與主戰鬥 / 競技場的同步規則。

---

## 1. Local Cache

Bootstrap 會把 Config 相關資料寫入 `user://config/`，`ConfigScene` 開啟時先讀 `GameState` 已載入的快取資料：

| 路徑 | 內容 | 資料來源 |
| --- | --- | --- |
| `user://config/player_cats.json` | 玩家持有貓咪清單，包含 `playerCatId`、`catCatalogId`、`displayName`、`catFoodLevel`、`rank`、`isOwned` | `/api/auth/bootstrap` |
| `user://config/teams.json` | 四種隊伍的最新已確認設定，包含 `teamType`、`members[]` | `/api/auth/bootstrap` 與 Config API 成功回應 |

---

## 2. Runtime State

`GameState` 是 Config 相關資料的前端單一來源：

| 欄位 / 方法 | 說明 |
| --- | --- |
| `player_cats_data: Array` | 玩家持有貓咪快取 |
| `teams_data: Dictionary` | 隊伍快取，key 為 `Boss` / `Dungeon` / `ArenaAttack` / `ArenaDefense` |
| `get_team(team_type)` | 取得指定隊伍資料 |
| `get_config_owned_cats()` | 取得 `isOwned = true` 的貓咪 |
| `update_player_teams(data)` | 更新隊伍快取並寫回 `user://config/teams.json` |
| `apply_active_team_from_config(teamType)` | 依指定隊伍重建目前戰鬥使用的 `player_team` 與 `skill_delays` |
| `player_team: Array` | 目前戰鬥場景會實際上場的 `playerCatId` 清單 |

---

## 3. ConfigScene Draft Flow

`ConfigScene` 不會在每次加入 / 移除 / 調整延遲時立刻送 API。

### 3.1 Draft State

- 每個頁籤 `boss / dungeon / arena_attack / arena_defense` 都有自己的本地 draft。
- 加入貓咪、移除貓咪、調整延遲，都只會先修改 draft 並標記 dirty。
- 使用者按下 `套用隊伍變更` 時，才會把目前頁籤的 draft 整組送出。

### 3.2 Slot Behavior

- draft 內的 `members` 會保留固定槽位概念。
- 移除中間槽位時，不會讓後面的貓自動補位。
- 新加入貓咪時，會優先補到第一個空槽。
- `slotNo` 由前端明確傳給後端，前後端都以 `slotNo` 當成唯一槽位依據。

### 3.3 Save Result

- API 成功回傳後，`ConfigScene._apply_team_update()` 會更新 `GameState.teams_data`。
- `GameState._save_config_cache("teams", ...)` 會同步寫回 `user://config/teams.json`。
- 若此次儲存的是 `Boss` 隊伍，會再同步更新目前首頁戰鬥用的 `player_team` 與 `skill_delays`。

---

## 4. Config API

目前 `ConfigScene` 使用的隊伍 API 如下：

| 功能 | API | Client 呼叫 | 說明 |
| --- | --- | --- | --- |
| 取得所有隊伍 | `GET /api/config/teams` | `ApiClient.get_teams()` | 取得四種隊伍的最新已確認設定 |
| 整組覆蓋隊伍 | `PUT /api/config/teams/{teamType}` | `ApiClient.replace_team(type, members)` | 以目前頁籤 draft 覆蓋 server 隊伍內容 |

### 4.1 teamType Mapping

| Scene key | Route value | Backend enum |
| --- | --- | --- |
| `boss` | `boss` | `Boss` |
| `dungeon` | `dungeon` | `Dungeon` |
| `arena_attack` | `arena_attack` | `ArenaAttack` |
| `arena_defense` | `arena_defense` | `ArenaDefense` |

### 4.2 PUT Request Shape

```json
{
  "members": [
    {
      "slotNo": 0,
      "playerCatId": 42,
      "initialDelaySeconds": 0.0
    },
    {
      "slotNo": 4,
      "playerCatId": 99,
      "initialDelaySeconds": 2.0
    }
  ]
}
```

### 4.3 Validation Rules

- 每隊最多 5 隻貓。
- `slotNo` 必須介於 0 到 4，且同一隊內不可重複。
- 同一隻貓不可在同一隊內重複出現。
- 所有 `playerCatId` 必須屬於當前玩家且為 `isOwned = true`。
- `initialDelaySeconds` 不可為負數。
- 四種隊伍 `Boss / Dungeon / ArenaAttack / ArenaDefense` 都允許設定 `initialDelaySeconds`。
- 前端可透過缺少某些 `slotNo` 來保留空槽，例如只送出 `slotNo = 0` 與 `slotNo = 4` 代表中間槽位留空。

---

## 5. Bootstrap Response Shape

`GET /api/auth/bootstrap` 會回傳 `playerTeams`：

```json
{
  "playerTeams": [
    {
      "teamType": "Boss",
      "members": [
        {
          "slotNo": 0,
          "playerCatId": 42,
          "catCatalogId": 3,
          "catDisplayName": "黑貓",
          "catFoodLevel": 5,
          "rank": 2,
          "initialDelaySeconds": 0.0
        }
      ]
    },
    { "teamType": "Dungeon", "members": [] },
    { "teamType": "ArenaAttack", "members": [] },
    { "teamType": "ArenaDefense", "members": [] }
  ]
}
```

---

## 6. Runtime Sync Rules

- `GameState.apply_active_team_from_config(teamType)` 會依 `slotNo` 重建目前戰鬥要使用的 `player_team` 與 `skill_delays`。
- Bootstrap / 本地快取載入完成後，首頁預設會套用 `Boss` 隊伍。
- `ConfigScene` 儲存 `Boss` 隊伍後，若 `BattleScene` 仍常駐於 `HomeShellScene`，會直接呼叫 `BattleScene.restart_with_latest_team()`，不用等待勝負結算才重新讀隊伍。
- `ConfigScene` 儲存 `ArenaAttack` / `ArenaDefense` 後，會更新快取，但不會主動重啟任何競技場戰鬥。
- `ArenaScene` 進入競技場攻擊戰前，會優先套用 `ArenaAttack`；若未設定才 fallback 到 `Boss`。延遲也會一起透過 `GameState.apply_active_team_from_config(...)` 載入。
- `ArenaDefense` 目前也允許設定並儲存延遲，但 client 端沒有單獨的本地防守戰鬥入口；它主要是提供後端與對戰流程使用的隊伍設定資料。

---

## 7. Related Files

| 路徑 | 職責 |
| --- | --- |
| `MeowPartyDashClient/scripts/configs/ConfigScene.gd` | Config UI、draft 狀態、確認送出 |
| `MeowPartyDashClient/scripts/ApiClient.gd` | `get_teams`、`replace_team` |
| `MeowPartyDashClient/scripts/gamestate/GameState.gd` | Config 快取與當前戰鬥隊伍同步 |
| `MeowPartyDashClient/scripts/battle/battle_scene.gd` | Boss 隊伍儲存後的首頁戰鬥重啟 |
| `MeowPartyDashClient/scripts/arenaScene/ArenaScene.gd` | 競技場攻擊戰前套用有效隊伍 |
| `MeowPartyDashAPI/Controllers/ConfigController.cs` | Config API 路由入口 |
| `MeowPartyDashAPI/MeowPartyDashAPI.Application/Services/Config/ConfigService.cs` | 隊伍驗證、整組覆蓋、slot 保留 |

---

## 8. Sequence Summary

```text
Bootstrap
  -> /api/auth/bootstrap
  -> GameState.apply_player_bootstrap()
  -> user://config/player_cats.json
  -> user://config/teams.json
  -> GameState.apply_active_team_from_config("Boss")

ConfigScene open
  -> read GameState.player_cats_data / teams_data
  -> build per-tab draft from cached team

User edits team
  -> local draft only
  -> dirty state = true

User presses 套用隊伍變更
  -> ApiClient.replace_team()
  -> PUT /api/config/teams/{teamType}
  -> TeamResponse
  -> GameState.teams_data update
  -> save user://config/teams.json
  -> if Boss: GameState.apply_active_team_from_config("Boss")
  -> if BattleScene is mounted: BattleScene.restart_with_latest_team()

ArenaScene challenge
  -> resolve effective team type (ArenaAttack first, Boss fallback)
  -> GameState.apply_active_team_from_config(teamType)
  -> change_scene_to_file(ArenaBattleScene)
```
