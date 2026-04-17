# 15. Settings And Lineup Data Architecture

> Last updated: 2026-04-17

本文記錄 2026-04 後 `ConfigScene` 拆分完成後的實際資料流：

- `ConfigScene`：真正的設定中心
- `LineupScene`：原本的編隊 / 延遲設定頁

這份文件同時說明角色資料、帳號區塊、兌換碼、本機音量設定，以及舊編隊功能如何延續到 `LineupScene`。

---

## 1. Local Cache

目前設定中心與編隊相關的本機檔案如下：

| 路徑 | 內容 | 資料來源 |
| --- | --- | --- |
| `user://config/player_cats.json` | 玩家持有貓咪清單，包含 `playerCatId`、`catCatalogId`、`displayName`、`catFoodLevel`、`rank`、`isOwned` | `/api/auth/bootstrap` |
| `user://config/teams.json` | 已確認的四種隊伍設定，包含 `teamType`、`members[]` | `/api/auth/bootstrap` 與 `PUT /api/config/teams/{teamType}` |
| `user://client_settings.json` | 本機音量與靜音設定 | `ClientSettings` singleton |

`user://client_settings.json` 固定結構：

```json
{
  "masterVolume": 1.0,
  "bgmVolume": 0.72,
  "sfxVolume": 0.9,
  "masterMuted": false,
  "bgmMuted": false,
  "sfxMuted": false
}
```

---

## 2. Runtime State Ownership

### 2.1 `GameState`

`GameState` 是設定中心與編隊相關資料的主要來源：

| 欄位 / 方法 | 說明 |
| --- | --- |
| `player_data.display_name` | 暱稱 |
| `player_data.player_name` | 角色名稱 |
| `player_data.avatar_id` | 設定中心選取的頭像 id |
| `player_data.bio` | 自介 |
| `player_data.birthday` | 生日字串 |
| `player_data.gender_type` | 性別 enum 名稱字串 |
| `player_data.region` | 地區 |
| `player_data.linked_providers` | 已綁定 provider 名稱清單 |
| `teams_data` | 已確認隊伍快取，key 為 `Boss` / `Dungeon` / `ArenaAttack` / `ArenaDefense` |
| `get_team(team_type)` | 取得指定隊伍 |
| `get_config_owned_cats()` | 取得 `isOwned = true` 的貓咪清單 |
| `apply_profile_response(data)` | 套用 `profile/me` 回應並同步更新 `player_data` |
| `apply_wallet_snapshot(data)` | 套用兌換碼成功後的最新錢包快照 |
| `apply_active_team_from_config(teamType)` | 依指定隊伍重建目前戰鬥使用中的 `player_team` 與 `skill_delays` |
| `player_profile_changed` | 設定中心儲存成功後發送，首頁 HUD 會跟著刷新 |
| `player_wallet_changed` | 兌換碼發獎後發送，首頁資源列會跟著刷新 |

### 2.2 `ClientSettings`

`ClientSettings` 是獨立 singleton，專門管理本機音量設定：

| 方法 | 說明 |
| --- | --- |
| `get_settings()` | 取得完整本機設定 |
| `set_volume(busKey, value)` | 更新 `master` / `bgm` / `sfx` 音量 |
| `set_muted(busKey, muted)` | 更新靜音狀態 |
| `settings_changed` | 設定變更時發送 |

`ClientSettings` 會在 `_ready()`：

1. 讀取 `user://client_settings.json`
2. 呼叫 `UiAudio.ensure_audio_buses()`
3. 把設定套用到 `Master` / `BGM` / `SFX` bus

---

## 3. ConfigScene Data Flow

### 3.1 Open Flow

- 首頁 `BattleScene` 左上角頭像 / 名稱區塊可點擊，開啟 `ConfigScene` overlay。
- `ConfigScene` 開啟後先用 `GameState.player_data` 組出本地快照，立即畫出表單內容。
- 接著呼叫 `ApiClient.get_profile_me()` 對 `GET /api/profile/me` 做同步。
- 若 API 失敗，畫面保留本地快取並用 Toast 提示「設定資料使用快取」。

### 3.2 Profile Form

設定中心角色資料區塊包含：

- 預設頭像
- 暱稱
- 角色名稱
- 自介
- 生日
- 性別
- 地區

Client 驗證規則：

- `displayName` 不可空白
- `playerName` 不可空白
- `bio` 最多 140 字
- `birthday` 若有填寫，格式需為 `YYYY-MM-DD`

儲存流程：

1. 使用者編輯表單後會標記 `_profile_dirty = true`
2. 按下 `儲存角色資料`
3. `ApiClient.update_profile_me(payload)` 呼叫 `PUT /api/profile/me`
4. 成功後 `GameState.apply_profile_response(profile)`
5. `ConfigScene` 重新套用回傳資料並清掉 dirty state
6. `BattleScene` 透過 `player_profile_changed` 立即刷新左上角頭像與名稱

### 3.3 Account / OAuth Section

帳號資料區塊顯示：

- `account`
- `playerPublicId`
- `linkedProviders`

目前 provider 卡片固定為：

- `Google`
- `Apple`

規則：

- 若 provider 在 `linkedProviders` 內，顯示 `已綁定`
- 否則顯示 `即將開放`
- 按鈕維持 disabled，本期不啟動真正授權流程

### 3.4 Redeem Code Flow

設定中心帳號區塊內建兌換碼輸入：

1. 玩家輸入 code 後按下 `兌換`
2. `ApiClient.redeem_code(code)` 呼叫 `POST /api/redeem-codes/redeem`
3. 成功時取出 `walletSnapshot` 並呼叫 `GameState.apply_wallet_snapshot(...)`
4. 顯示獎勵列表 Dialog
5. 額外顯示成功 Toast

失敗時：

- 顯示錯誤 Toast
- 不修改本地錢包

### 3.5 Audio Settings Flow

設定中心遊戲設定區塊目前只處理本機音量：

- `總音量`
- `背景音樂`
- `音效`

每列都包含：

- slider
- 百分比文字
- 靜音 checkbox

資料流：

1. 開啟設定中心時，從 `ClientSettings.get_settings()` 讀值
2. 調整 slider 時，呼叫 `ClientSettings.set_volume(busKey, value)`
3. 切換靜音時，呼叫 `ClientSettings.set_muted(busKey, pressed)`
4. `ClientSettings` 立即寫回 `user://client_settings.json`
5. `UiAudio.apply_settings(...)` 立即更新 `Master` / `BGM` / `SFX`

---

## 4. LineupScene Draft Flow

舊版 `ConfigScene` 的隊伍設定功能已搬到 `LineupScene`。

### 4.1 Current Tabs

`LineupScene` 目前維持四種隊伍頁籤：

- `boss`
- `dungeon`
- `arena_attack`
- `arena_defense`

### 4.2 Draft State

- 每個頁籤都有自己的本地 draft。
- 加入貓咪、移除貓咪、調整 `initialDelaySeconds`，都只會先改本地 draft。
- 使用者按下儲存後，才會把當前頁籤送往 `PUT /api/config/teams/{teamType}`。

### 4.3 Slot Rules

- draft 以固定 `slotNo` 為主，不做自動壓縮。
- 移除中間槽位時，後面成員不會自動前移。
- 新加入的貓咪會補到第一個空槽。
- `slotNo` 仍是前後端共同的正式站位欄位。

### 4.4 Save Result

- API 成功後，`LineupScene` 會更新 `GameState.teams_data` 與 `user://config/teams.json`。
- 若儲存的是 `Boss` 隊伍，會同步 `GameState.apply_active_team_from_config("Boss")`。
- 若首頁 `BattleScene` 仍掛在 `HomeShellScene` 底下，會直接重新套用最新主隊伍，讓首頁戰鬥立即反映新編隊。

---

## 5. Related Files

| 路徑 | 職責 |
| --- | --- |
| `MeowPartyDashClient/scripts/configs/ConfigScene.gd` | 設定中心 UI、角色資料、帳號區塊、兌換碼、本機音量 |
| `MeowPartyDashClient/scripts/lineup/LineupScene.gd` | 編隊 UI、draft 狀態、隊伍儲存 |
| `MeowPartyDashClient/scripts/lineup/LineupConstants.gd` | 編隊頁常數與 type mapping |
| `MeowPartyDashClient/scripts/gamestate/GameState.gd` | 角色資料、錢包快照、隊伍快取、首頁同步 |
| `MeowPartyDashClient/scripts/gamestate/ClientSettings.gd` | 本機音量設定存取與套用 |
| `MeowPartyDashClient/scripts/ui/UiAudio.gd` | `Master` / `BGM` / `SFX` bus 與播放入口 |
| `MeowPartyDashClient/scripts/ApiClient.gd` | `get_profile_me`、`update_profile_me`、`redeem_code`、`replace_team` |
| `MeowPartyDashClient/scripts/battle/battle_scene.gd` | 左上角設定入口、首頁 HUD 即時刷新、BGM 播放 |
| `MeowPartyDashAPI/Controllers/ProfileController.cs` | `GET/PUT /api/profile/me` |
| `MeowPartyDashAPI/Controllers/RedeemCodesController.cs` | `POST /api/redeem-codes/redeem` |
| `MeowPartyDashAPI/Controllers/ConfigController.cs` | `PUT /api/config/teams/{teamType}` |

---

## 6. Sequence Summary

```text
Bootstrap
  -> /api/auth/bootstrap
  -> GameState.apply_player_bootstrap()
  -> player_data now contains displayName / playerName / avatarId / bio / birthday / genderType / region / linkedProviders
  -> user://config/player_cats.json
  -> user://config/teams.json
  -> Boss team applied to home battle

ConfigScene open
  -> build from GameState.player_data local snapshot
  -> GET /api/profile/me
  -> GameState.apply_profile_response()
  -> refresh form

Profile save
  -> validate local form
  -> PUT /api/profile/me
  -> GameState.apply_profile_response()
  -> player_profile_changed
  -> BattleScene refresh HUD

Redeem code
  -> POST /api/redeem-codes/redeem
  -> GameState.apply_wallet_snapshot()
  -> player_wallet_changed
  -> reward dialog + success toast

Audio change
  -> ClientSettings.set_volume / set_muted
  -> save user://client_settings.json
  -> UiAudio.apply_settings()

LineupScene save
  -> edit local draft only
  -> PUT /api/config/teams/{teamType}
  -> GameState.teams_data update
  -> save user://config/teams.json
  -> if Boss: apply_active_team_from_config("Boss")
```
