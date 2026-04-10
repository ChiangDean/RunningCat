# 14. [鏟屎官] 資料架構 — [user://] 快取 × [API] 即時操作

> 更新日期：2026-04-10

本文件記錄 [鏟屎官頁面]（ScooperScene）遷移至後端 [API] 驅動後，前端的資料儲存策略與即時操作對應表。

---

## 一、[user://] 快取資料

### 1-A. [Catalog] 快取（靜態設定）

以下資料在 [Bootstrap]（登入同步）時由後端一次帶回，存入 `user://catalog/`。
客戶端啟動時優先讀取快取，[Bootstrap] 成功後覆蓋更新。

| 檔案路徑 | 內容 | 更新時機 |
|----------|------|---------|
| `user://catalog/equipment_catalog.json` | [裝備] 目錄（ID、名稱、解鎖等級、各項費用、加成屬性） | [Bootstrap] |
| `user://catalog/memory_catalog.json` | [回憶] 目錄（ID、名稱、說明、圖片、解鎖費用、加成屬性） | [Bootstrap] |
| `user://catalog/treasure_catalog.json` | [寶藏] 目錄（ID、名稱、說明、來源、效果清單） | [Bootstrap] |
| `user://catalog/achievement_catalog.json` | [成就] 目錄（ID、名稱、分類、條件、獎勵清單） | [Bootstrap] |
| `user://catalog/ability_catalog.json` | [特殊能力] 目錄（ID、名稱、說明、效果） | [Bootstrap] |

### 1-B. [Scooper Live Data] 快取（玩家即時資料）

以下資料在 [Bootstrap] 時由後端帶回並持久化至 `user://player_data/scooper/`。
進入 Tab 時先從快取渲染（stale-while-revalidate），再背景呼叫 [API] 更新。
特定操作後透過 `GameState.update_scooper_*()` 同時更新記憶體與本地快取。

| 檔案路徑 | 內容 | 更新時機 |
|----------|------|---------|
| `user://player_data/scooper/profile.json` | [鏟屎官] 個人資料（等級、經驗、金幣等） | [Bootstrap]、[鏟屎]、裝備操作後、領取成就後 |
| `user://player_data/scooper/equipment.json` | [裝備] 列表（含擁有狀態、等級、損壞等） | [Bootstrap]、裝備操作後（購買/升級/修復/就醫） |
| `user://player_data/scooper/ability.json` | [特殊能力] 列表 | [Bootstrap]、進入 [鏟屎官] Tab 時 API 更新 |
| `user://player_data/scooper/memory.json` | [回憶] 列表（含解鎖狀態） | [Bootstrap]、解鎖回憶後 |
| `user://player_data/scooper/treasure.json` | [寶藏] 列表（含持有數量） | [Bootstrap]、進入 [寶藏] Tab 時 API 更新 |
| `user://player_data/scooper/achievement.json` | [成就] 列表（含進度與領取狀態） | [Bootstrap]、領取成就後 |

### 1-C. 既有快取（不變）

| 檔案路徑 | 內容 |
|----------|------|
| `user://auth_session.json` | 登入 [Token]（[AccessToken] + [RefreshToken]） |
| `user://player_data.json` | [玩家] 基本資料（等級、貨幣、擁有貓咪等） |
| `user://device_id.txt` | [裝置ID] |

---

## 二、即時 [API] 操作與快取更新

以下動作即時呼叫後端 [API]，回傳後透過 `GameState.update_scooper_*()` 更新記憶體與本地快取。

### [鏟屎官] Tab

| 動作 | [API] 端點 | 方法 | 觸發時機 | 更新快取 |
|------|-----------|------|---------|---------|
| 取得 [鏟屎官] 個人資料 | `GET /api/scooper/profile` | `ApiClient.get_scooper_profile()` | 切換至 [鏟屎官] Tab | profile |
| [鏟屎] | `POST /api/scooper/profile/scoop` | `ApiClient.scoop_poop(count)` | 點擊「鏟屎」按鈕 | profile |
| 取得 [裝備] 列表（含玩家狀態） | `GET /api/scooper/equipment` | `ApiClient.get_equipment_list()` | 切換至 [鏟屎官] Tab、裝備操作後 | equipment |
| 購買 [裝備] | `POST /api/scooper/equipment/purchase` | `ApiClient.purchase_equipment(id)` | 點擊「購買」按鈕 | equipment + profile |
| 升級 [裝備] | `POST /api/scooper/equipment/upgrade` | `ApiClient.upgrade_equipment(id)` | 點擊「升級」按鈕 | equipment + profile |
| 修復 [裝備] | `POST /api/scooper/equipment/repair` | `ApiClient.repair_equipment(id)` | 點擊「修復」按鈕 | equipment + profile |
| [裝備] 就醫 | `POST /api/scooper/equipment/treat` | `ApiClient.treat_equipment(id)` | 點擊「就醫」按鈕 | equipment + profile |
| 取得 [特殊能力] 列表 | `GET /api/scooper/ability` | `ApiClient.get_abilities()` | 切換至 [鏟屎官] Tab | ability |

### [回憶] Tab

| 動作 | [API] 端點 | 方法 | 觸發時機 | 更新快取 |
|------|-----------|------|---------|---------|
| 取得 [回憶] 列表（含解鎖狀態） | `GET /api/scooper/memory` | `ApiClient.get_memories()` | 切換至 [回憶] Tab | memory |
| 解鎖 [回憶] | `POST /api/scooper/memory/unlock` | `ApiClient.unlock_memory(id)` | 確認解鎖 [回憶] | memory |

### [寶藏] Tab

| 動作 | [API] 端點 | 方法 | 觸發時機 | 更新快取 |
|------|-----------|------|---------|---------|
| 取得 [寶藏] 列表（含持有數量） | `GET /api/scooper/treasure` | `ApiClient.get_treasures()` | 切換至 [寶藏] Tab | treasure |

### [成就] Tab

| 動作 | [API] 端點 | 方法 | 觸發時機 | 更新快取 |
|------|-----------|------|---------|---------|
| 取得 [成就] 列表（含進度） | `GET /api/scooper/achievement` | `ApiClient.get_achievements()` | 切換至 [成就] Tab | achievement |
| 領取 [成就] 獎勵 | `POST /api/scooper/achievement/claim` | `ApiClient.claim_achievement(id)` | 點擊「領取獎勵」按鈕 | achievement + profile |

---

## 三、資料流圖

```
[登入/Bootstrap]
    │
    ▼
┌──────────────────┐
│   後端 API        │
│  /api/auth/bootstrap │
└────────┬─────────┘
         │ 回傳 playerData + 5 個 catalog + 6 個 scooper live data
         ▼
┌──────────────────┐
│  GameState        │
│  apply_player_bootstrap() │
│  ├─ player_data              │ ← user://player_data.json
│  ├─ scooper_*_catalog (×5)   │ ← user://catalog/*.json
│  └─ scooper_*_data   (×6)   │ ← user://player_data/scooper/*.json
└──────────────────┘

[ScooperScene 切換 Tab]
    │
    ├─ (1) 先從 scooper_*_data 快取渲染 UI
    │
    ├─ (2) 背景呼叫 API 拉新資料
    │       │
    │       ▼
    │  ┌──────────────────┐
    │  │  ApiClient        │
    │  │  get_*() / post_*()│ ─────→ 後端 Scooper API
    │  │  401 → 自動 refresh      │
    │  │  → 失敗 → 跳回 StartScene │
    │  └────────┬─────────┘
    │           │ 回傳 data
    │           ▼
    │  ┌──────────────────┐
    │  │  GameState        │
    │  │  update_scooper_*()│ ← 更新記憶體 + 持久化快取
    │  └────────┬─────────┘
    │           │
    └───────────┤
                ▼
┌──────────────────┐
│  ScooperScene UI  │
│  _refresh_*_tab() │
└──────────────────┘
```

---

## 四、[Combat Bonus] 計算

戰鬥加成（`get_equipment_bonuses()`、`get_memory_bonuses()`、`get_treasure_combat_bonuses()`）在 `GameState` 中實作。

優先讀取 [API] 即時資料（`scooper_equipment_data`、`scooper_memory_data`、`scooper_treasure_data`），fallback 至本地 `res://data/default/` JSON 設定。

由於 [Bootstrap] 時已將 live data 持久化至本地快取，啟動時即可載入，戰鬥加成不再依賴玩家是否曾進入 [鏟屎官] 頁面。

---

## 五、關鍵檔案

| 路徑 | 角色 |
|------|------|
| `scripts/ApiClient.gd` | 統一 [HTTP API] 客戶端 [Autoload] |
| `scripts/GameState.gd` | 全域狀態管理 + [Catalog] 快取 + [Scooper Live Data] 快取 |
| `scripts/ScooperScene.gd` | [鏟屎官] 場景 Shell（Tab 切換、共用方法） |
| `scripts/scooper_tab_scooper.gd` | [鏟屎官] Tab（個人資料、鏟屎、能力、裝備） |
| `scripts/scooper_tab_memory.gd` | [回憶] Tab（列表、解鎖） |
| `scripts/scooper_tab_treasure.gd` | [寶藏] Tab（列表顯示） |
| `scripts/scooper_tab_achievement.gd` | [成就] Tab（列表、領取） |
| `project.godot` | [Autoload] 註冊（GameState, DialogManager, ApiClient） |
