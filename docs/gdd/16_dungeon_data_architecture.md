# 16. [地下城] 資料架構 — [Bootstrap] 快取 × [API] 權威結算

> 更新日期：2026-04-11

本文件記錄 [地下城頁面]（DungeonScene）遷移至後端 [API] 驅動後，前端的資料儲存策略、[Bootstrap] 載入內容與即時操作對應表。

---

## 一、[Bootstrap] 與 [user://] 快取資料

### 1-A. 本地靜態設定（`res://data/default/`）

以下資料仍由客戶端內建 JSON 提供，主要用於戰鬥參數與本地 fallback。

| 檔案路徑 | 內容 | 用途 |
|----------|------|------|
| `res://data/default/dungeon_config.json` | 地下城靜態設定（key、名稱、敵方基礎能力、倍率、獎勵公式） | 地下城戰鬥參數、本地 fallback |

### 1-B. [Dungeon Overview] 快取（玩家即時資料）

以下資料在 [Bootstrap]（登入同步）時由後端帶回，存入 `user://config/dungeon.json`。

客戶端啟動時可先讀取快取渲染 UI，[Bootstrap] 成功後再覆蓋更新。

| 檔案路徑 | 內容 | 更新時機 |
|----------|------|---------|
| `user://config/dungeon.json` | 地下城列表（`dungeonId`、`key`、名稱、說明、剩餘門票、剩餘廣告補票次數、最高通關層數） | [Bootstrap]、取得列表、看廣告補票、掃蕩、挑戰結算後 |

### 1-C. 既有玩家資料（同步更新）

地下城操作雖然只快取 overview，但回傳 payload 也會同步更新玩家資源欄位。

| 檔案路徑 | 內容 | 更新欄位 |
|----------|------|---------|
| `user://player_data.json` | 玩家基礎資料 | `catFood`、`specialCatFood`、`diamonds`、`trapCages`、`whiskerShards` |

---

## 二、[Bootstrap] 回傳內容

登入成功後，前端呼叫：

| 動作 | [API] 端點 | 方法 |
|------|-----------|------|
| 玩家初始化同步 | `GET /api/auth/bootstrap` | `StartScene` 直接呼叫 |

本次地下城改動後，[Bootstrap] 回傳的 `PlayerBootstrapResponse` 額外包含：

| 欄位 | 型別 | 說明 |
|------|------|------|
| `dungeons` | `List<DungeonItemResponse>` | 地下城 overview 清單 |

前端在 `GameState.apply_player_bootstrap()` 中解析 `dungeons`，並呼叫：

| 方法 | 作用 |
|------|------|
| `GameState.apply_dungeon_overview(data)` | 更新玩家資源欄位 + 套用 dungeon overview |
| `GameState.update_dungeon_overview(data)` | 更新記憶體中的 `dungeon_overview_data` 並寫入 `user://config/dungeon.json` |

---

## 三、即時 [API] 操作與快取更新

地下城的門票扣除、廣告補票、掃蕩獎勵與挑戰結算，改為完全由後端權威計算。

### 3-A. [DungeonScene] 列表操作

| 動作 | [API] 端點 | 方法 | 觸發時機 | 更新快取 |
|------|-----------|------|---------|---------|
| 取得地下城列表 | `GET /api/dungeon` | `ApiClient.get_dungeon_overview()` | 進入 [DungeonScene] 且本地快取為空時 | dungeon |
| 看廣告補票 | `POST /api/dungeon/{dungeonId}/ad-ticket` | `ApiClient.grant_dungeon_ad_ticket(id)` | 點擊「看廣告補票」 | dungeon + player_data |
| 掃蕩 | `POST /api/dungeon/{dungeonId}/sweep` | `ApiClient.sweep_dungeon(id)` | 點擊「掃蕩」 | dungeon + player_data |

### 3-B. [DungeonBattleScene] 挑戰結算

| 動作 | [API] 端點 | 方法 | 觸發時機 | 更新快取 |
|------|-----------|------|---------|---------|
| 挑戰通關結算 | `POST /api/dungeon/{dungeonId}/challenge` | `ApiClient.complete_dungeon_challenge(id, targetFloor)` | 戰鬥結果為勝利後 | dungeon + player_data |

### 3-C. 回傳資料型別

#### `GET /api/dungeon`

回傳 `DungeonOverviewResponse`：

| 欄位 | 說明 |
|------|------|
| `catFood` | 玩家普通乾糧 |
| `specialCatFood` | 玩家特殊乾糧 |
| `diamonds` | 玩家鑽石 |
| `trapCages` | 玩家誘捕籠 |
| `whiskerShards` | 玩家鬍鬚碎片 |
| `dungeons` | 地下城清單 |

#### `POST /api/dungeon/{id}/sweep`、`POST /api/dungeon/{id}/challenge`

回傳 `DungeonActionResponse`：

| 欄位 | 說明 |
|------|------|
| `runType` | `Sweep` / `Challenge` |
| `resultType` | `SweepSuccess` / `Win` |
| `targetFloor` | 本次處理的樓層 |
| `reward` | 本次獎勵內容 |
| `overview` | 更新後的 `DungeonOverviewResponse` |

前端收到後：

| 方法 | 作用 |
|------|------|
| `GameState.apply_dungeon_overview(overview)` | 同步玩家資源與 dungeon overview |
| `DungeonSceneActions.show_reward_popup()` / `DungeonBattleScene._show_reward_popup()` | 只負責顯示結果，不自行扣票與發獎 |

---

## 四、資料流圖

```
[登入/Bootstrap]
    │
    ▼
┌──────────────────────┐
│   後端 API            │
│  GET /api/auth/bootstrap │
└─────────┬────────────┘
          │ 回傳 playerData + dungeons
          ▼
┌──────────────────────┐
│  GameState            │
│  apply_player_bootstrap() │
│  ├─ player_data                │ ← user://player_data.json
│  └─ dungeon_overview_data      │ ← user://config/dungeon.json
└──────────────────────┘

[進入 DungeonScene]
    │
    ├─ (1) 先讀 dungeon_overview_data 快取渲染
    │
    └─ (2) 若快取為空，呼叫 GET /api/dungeon
                │
                ▼
        GameState.apply_dungeon_overview()
                │
                ▼
           DungeonScene UI

[掃蕩 / 補票 / 挑戰勝利]
    │
    ▼
┌──────────────────────┐
│  ApiClient            │
│  POST /api/dungeon/... │
└─────────┬────────────┘
          │ 回傳 overview / reward
          ▼
┌──────────────────────┐
│  GameState            │
│  apply_dungeon_overview() │
└─────────┬────────────┘
          │
          ├─ 更新 user://config/dungeon.json
          ├─ 更新 user://player_data.json
          ▼
     UI 顯示最新門票 / 樓層 / 獎勵
```

---

## 五、前端責任切分

### 5-A. [GameState]

| 方法 / 欄位 | 角色 |
|-------------|------|
| `dungeon_overview_data` | 記憶體中的地下城即時資料 |
| `apply_dungeon_overview()` | 套用 API/Bootstrap 回傳資料 |
| `update_dungeon_overview()` | 持久化 `user://config/dungeon.json` |
| `get_dungeon_entry_by_id()` | 供 UI / 操作層查詢單一地下城 |
| `dungeon_battle_id` | 戰鬥場景傳遞用 dungeonId |
| `dungeon_battle_key` | 戰鬥場景傳遞用本地 config key |
| `dungeon_battle_level` | 戰鬥場景傳遞用目標樓層 |

### 5-B. [DungeonScene]

`DungeonScene` 已拆分至 `scripts/dungeon/`：

| 路徑 | 角色 |
|------|------|
| `scripts/dungeon/DungeonScene.gd` | 場景 shell，轉接 UI / Actions |
| `scripts/dungeon/DungeonSceneUI.gd` | 建立列表 UI、刷新按鈕狀態 |
| `scripts/dungeon/DungeonSceneActions.gd` | 呼叫 API、處理回傳與跳場景 |

### 5-C. [DungeonBattleScene]

| 路徑 | 角色 |
|------|------|
| `scripts/battle/dungeon_battle_scene.gd` | 戰鬥演出與勝利後 challenge 結算 API 呼叫 |

重點規則：

1. 前端不再直接扣除地下城門票。
2. 前端不再直接更新最高通關層數。
3. 前端不再直接把地下城獎勵加到 `PlayerData`。
4. 上述三項都以後端回傳的 `overview` 與 `reward` 為準。

---

## 六、關鍵檔案

| 路徑 | 角色 |
|------|------|
| `scripts/ApiClient.gd` | 地下城 API 呼叫入口 |
| `scripts/gamestate/GameState.gd` | 地下城 bootstrap 套用與快取管理 |
| `scripts/dungeon/DungeonScene.gd` | 地下城場景 shell |
| `scripts/dungeon/DungeonSceneUI.gd` | 地下城列表 UI |
| `scripts/dungeon/DungeonSceneActions.gd` | 地下城操作行為 |
| `scripts/battle/dungeon_battle_scene.gd` | 地下城戰鬥與挑戰結算 |
| `data/default/dungeon_config.json` | 地下城靜態設定 |

