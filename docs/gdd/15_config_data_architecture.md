# 15. Config Data Architecture

> 更新日期：2026-04-10

本文件記錄 `ConfigScene` 在改為後端 API 驅動後的資料來源、前端草稿行為、確認送出流程，以及相關 API 契約。

---

## 1. Local Cache

Bootstrap 會把設定資料寫入 `user://config/`，`ConfigScene` 開啟時先讀取 `GameState` 已載入的快取資料：

| 路徑 | 用途 | 寫入來源 |
|------|------|---------|
| `user://config/player_cats.json` | 玩家持有貓咪清單，包含 `playerCatId`、`catCatalogId`、`displayName`、`catFoodLevel`、`rank`、`isOwned` | `/api/auth/bootstrap` |
| `user://config/teams.json` | 四種隊伍的最新已確認設定，包含 `teamType`、`members[]` | `/api/auth/bootstrap` 與 Config API 成功回應 |

---

## 2. Runtime State

`GameState` 是 Config 資料的前端單一來源：

| 成員 | 說明 |
|------|------|
| `player_cats_data: Array` | 持有貓咪快取 |
| `teams_data: Dictionary` | 隊伍快取，key 為 `Boss` / `Dungeon` / `ArenaAttack` / `ArenaDefense` |
| `get_team(team_type)` | 取得指定隊伍；若不存在，回傳空 members |
| `get_config_owned_cats()` | 取得 `isOwned = true` 的貓咪 |
| `update_player_cats(data)` | 更新貓咪快取並寫回 `user://config/player_cats.json` |
| `update_player_teams(data)` | 更新隊伍快取並寫回 `user://config/teams.json` |
| `player_team: Array` | 戰鬥場景使用的 Boss 隊伍 `playerCatId` 清單，只會在 Boss 隊伍成功保存後更新 |

---

## 3. ConfigScene Draft Flow

`ConfigScene` 現在不再於每次加入/移除/調整延遲時直接送 API。

### 3.1 Draft 規則

- 每個頁籤 `boss / dungeon / arena_attack / arena_defense` 都有自己的本地 draft。
- 點擊 `Add`、`Remove`、`+`、`-` 只會修改目前頁籤的 draft 與 dirty 狀態。
- Team 區域最下方會顯示 `套用隊伍變更` 按鈕。
- 只有按下 `套用隊伍變更`，才會把目前頁籤整組 members 一次送到 API。
- 若切換頁籤或返回戰鬥場景前未按確認，未保存的 draft 不會寫回 `GameState.teams_data`。

### 3.2 Save 後行為

- API 成功回傳後，`ConfigScene._apply_team_update()` 會更新 `GameState.teams_data`。
- `GameState._save_config_cache("teams", ...)` 會同步寫回 `user://config/teams.json`。
- 若保存的是 `Boss` 隊伍，`GameState.player_team` 也會同步更新為最新已確認陣容。
- 該頁 draft 會重置為最新 server 回傳內容，dirty 狀態清除。

---

## 4. Config API

目前 `ConfigScene` 使用的隊伍 API 如下：

| 功能 | API | Client 呼叫 | 說明 |
|------|-----|-------------|------|
| 取得所有隊伍 | `GET /api/config/teams` | `ApiClient.get_teams()` | 取得四種隊伍的最新已確認設定 |
| 整組覆蓋隊伍 | `PUT /api/config/teams/{teamType}` | `ApiClient.replace_team(type, members)` | 以目前頁籤 draft 覆蓋 server 隊伍內容 |

### 4.1 `teamType` 對應

| Scene key | Route 值 | 後端 enum |
|-----------|----------|-----------|
| `boss` | `boss` | `Boss` |
| `dungeon` | `dungeon` | `Dungeon` |
| `arena_attack` | `arena_attack` | `ArenaAttack` |
| `arena_defense` | `arena_defense` | `ArenaDefense` |

### 4.2 `PUT /api/config/teams/{teamType}` Request

```json
{
  "members": [
    {
      "playerCatId": 42,
      "initialDelaySeconds": 0.0
    },
    {
      "playerCatId": 99,
      "initialDelaySeconds": 2.0
    }
  ]
}
```

### 4.3 驗證規則

- 每隊最多 5 隻貓。
- 同一隻貓不可在同一隊內重複出現。
- 所有 `playerCatId` 必須屬於當前玩家且為 `isOwned = true`。
- `initialDelaySeconds` 不可為負數。
- `arena_defense` 不接受非 0 的 `initialDelaySeconds`。
- 回應成功後會回傳完整 `TeamResponse`，供前端直接覆蓋快取。

---

## 5. Bootstrap Response Shape

`GET /api/auth/bootstrap` 內的 `playerTeams` 仍維持以下資料結構：

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
          "catDisplayName": "牛奶貓",
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

## 6. Related Files

| 路徑 | 角色 |
|------|------|
| `MeowPartyDashClient/scripts/configs/ConfigScene.gd` | Config UI、draft 狀態、確認送出 |
| `MeowPartyDashClient/scripts/ApiClient.gd` | `get_teams`、`replace_team` |
| `MeowPartyDashClient/scripts/gamestate/GameState.gd` | Config 快取讀寫與 Boss 已確認隊伍同步 |
| `MeowPartyDashAPI/Controllers/ConfigController.cs` | Config API 路由入口 |
| `MeowPartyDashAPI/MeowPartyDashAPI.Application/Services/Config/ConfigService.cs` | 隊伍驗證、整組覆蓋、slot 重建 |
| `MeowPartyDashAPI/MeowPartyDashAPI.Application/Models/Config/ReplaceTeamMembersRequest.cs` | 批次送出 request model |

---

## 7. Sequence Summary

```text
Bootstrap
  -> /api/auth/bootstrap
  -> GameState.apply_player_bootstrap()
  -> user://config/player_cats.json
  -> user://config/teams.json

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
  -> if Boss: update GameState.player_team
```
