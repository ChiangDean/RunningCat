# 九、活動系統

## 9-1 活動入口

主畫面底部導覽列：**配置 ／ 強化 ／ 活動 ／ 商店**

點擊「活動」進入活動頁，目前常駐內容包含：

| 功能 | 狀態 | 備註 |
|------|------|------|
| 地下城 | ✅ 實作 | 獨立票券制挑戰模式 |
| 競技場 | ✅ 實作 | 排名獎勵與對手刷新 |
| 寵物探險 | ✅ 實作 | 依 territory 解鎖的定時派遣系統 |

### 活動頁互動規則

- 活動頁使用共用卡片入口樣式，每張卡片顯示名稱、簡短描述與進入按鈕。
- 若活動內有可領取內容，活動卡片與主畫面 Activity 導覽按鈕皆可顯示紅點提示。
- 目前活動紅點來源包含：地下城、競技場、寵物探險。

---

## 9-2 地下城系統

### 概覽

地下城是獨立於主線推關的挑戰模式，各類型地下城提供不同獎勵。
每個地下城有獨立的**每日卷**，使用卷才能挑戰。
關卡無上限，難度依複利成長，玩家最高通關紀錄永久保存。

### 地下城種類（Config 可擴充）

| ID | 名稱 | 難度倍率 |
|-----|------|---------|
| `cat_food` | 乾糧地下城 | ×1.03 / 關 |
| `diamond` | 鑽石地下城 | ×1.03 / 關 |
| `whisker` | 鬍鬚地下城 | ×1.03 / 關 |

新地下城只需在 `dungeon_config.json` 的 `"dungeons"` 陣列新增一筆即可。

### 地下城卷（每種地下城各自計算）

| 來源 | 數量 | 重置 |
|------|------|------|
| 每日免費卷 | 2 張（Config 可調） | UTC+8 午夜 |
| 廣告卷 | 每種最多 2 張（Config 可調） | UTC+8 午夜 |
| 全服活動加碼 | Config `event_bonus_tickets` | 手動設定 |

卷的消耗優先順序：免費卷 → 廣告卷

**廣告卷**：目前廣告功能待實作。
卷用完後，按鈕顯示「▶ 看廣告獲得卷」，點擊彈出提示視窗「可以透過看廣告獲得地下城卷」，可按確認或取消。

### 挑戰流程

```text
地下城列表
  └─ [掃蕩 Lv.X]     → 秒拿 Lv.X 獎勵，消耗一張卷（須已通關至少 Lv.1）
  └─ [挑戰 Lv.X+1]   → 進入地下城戰鬥
        ├─ 勝利：消耗一張卷 → 更新最高紀錄 → 發放獎勵 → 返回列表
        └─ 失敗：不消耗卷 → 返回列表
```

### 敵人難度公式

```text
stats(level) = base_stat × difficulty_multiplier^(level - 1)
```

各地下城的 `base_hp`、`base_atk`、`base_def`、`difficulty_multiplier` 均在 Config 設定。

### 獎勵公式

| 地下城 | 普通乾糧 | 特殊乾糧 | 鑽石 | 誘捕籠 | 鬍鬚 |
|--------|---------|---------|------|--------|---------|
| 乾糧地下城 | 關卡 × 5 | 關卡 × 1 | — | — | — |
| 鑽石地下城 | — | — | 關卡 × 2 | `round(關卡/5 + 0.5)` | — |
| 鬍鬚地下城 | — | — | 關卡 × 2 | — | `round(關卡/10 + 0.5)` |

Config 中對應欄位：`cat_food_per_level`、`special_cat_food_per_level`、`diamonds_per_level`、`trap_cage_divisor`、`whisker_shard_divisor`（divisor=0 表示不給該獎勵）

### 誘捕籠道具

- 類型：消耗品，存放於 `player_data.trap_cages`
- 來源：鑽石地下城、未來其他活動
- 使用：在誘捕籠（GachaScene）頁面點擊「使用誘捕籠道具」，消耗 1 個執行 1 抽

### 通用鬍鬚

- 存放於 `player_data.whisker_shards`
- 來源：鬍鬚地下城、未來其他活動
- 使用方式：待強化系統支援通用鬍鬚指定貓咪後開放

---

## 9-3 寵物探險

### 概覽

寵物探險是依照主線 territory 進度逐步解鎖的定時派遣玩法。
玩家在每個探險區只能同時派出 1 隻貓，探險完成後可領取獎勵，再派出下一隻。

### 區域解鎖

| Territory 編號 | 區域名稱 | 解鎖條件 |
|------|------|------|
| 1 | 森林 | `current_territory >= 1` |
| 2 | 荒野 | `current_territory >= 2` |
| 3 | 雪原 | `current_territory >= 3` |
| 4 | 海岸 | `current_territory >= 4` |
| 5 | 王城 | `current_territory >= 5` |

- Client 端使用目前主線推關進度做預覽與鎖定顯示。
- Server 端需再次驗證 territory 條件，避免直接偽造請求。

### 區域設定

每個探險區域由 catalog 決定下列資料：

- `DisplayName`
- `TerritoryRequirement`
- `DurationHours`
- `RewardPoolJson`
- `IsEnabled`

區域時長可各自不同，例如 8h / 10h / 12h。

### 派遣限制

- 同一個區域同時只能有 1 筆進行中探險。
- 同一隻貓不能同時被多個區域使用。
- 只能派出玩家已擁有、且目前沒有在其他探險中的貓。

### 卡片狀態

探險頁每個區域卡片會呈現以下四種狀態：

| 狀態 | 顯示 |
|------|------|
| 已鎖定 | 灰色卡片，顯示解鎖條件，按鈕 disabled |
| 可派遣 | 顯示探險時長與派遣按鈕 |
| 探險中 | 顯示派遣中的貓咪與倒數計時 |
| 可領取 | 高亮卡片，顯示領取按鈕 |

### 領取與獎勵

- 探險完成條件：`StartedAtUtc + DurationHours <= UtcNow`
- 領取後發放獎勵並更新錢包快照
- 若獎勵含 `WhiskerShard`，會直接指定到本次探險的貓咪身上
- 領取完成後區域回到「可派遣」狀態

### 探險獎勵池

預設獎勵池可包含：

- `diamonds`
- `gold`
- `poop`
- `cat_food`
- `special_cat_food`
- `memory_shards`
- `whisker_shards`

數量與權重由 `RewardPoolJson` 決定，並可依區域難度遞增。

### UI / UX 規則

- 探險頁使用共用 `OverlaySceneChrome` 當作全螢幕 overlay 基底
- 區域卡片沿用共用卡片樣式與按鈕 palette
- 貓咪選擇使用共用 Dialog 呈現，不另做獨立 modal 系統
- 領取成功後沿用主畫面既有的 reward float 顯示流程

### 紅點規則

- 若任一探險區域已完成且可領取，活動頁中的「寵物探險」卡片顯示紅點
- 主畫面 Activity 導覽按鈕也會因探險可領取而顯示紅點
- 紅點判定以 server 回傳的 `isClaimable` 為主，並可用完成時間作為 fallback

---

## 9-4 Config / Catalog 設定位置

### 地下城

`data/default/dungeon_config.json`

```json
{
  "daily_free_tickets": 2,
  "ad_tickets_per_type": 2,
  "event_bonus_tickets": 0,
  "reset_timezone_offset_hours": 8,
  "dungeons": [ ... ]
}
```

新增地下城時，`dungeons` 陣列新增一筆；
特殊活動時調整 `event_bonus_tickets`；
調整每日卷數只需修改 `daily_free_tickets`。

### 寵物探險

探險區域由後端 expedition catalog 管理，至少包含：

```text
TerritoryIndex
DisplayName
TerritoryRequirement
DurationHours
RewardPoolJson
IsEnabled
```

前端 bootstrap 僅讀取 enabled 區域，並依 catalog 決定解鎖條件、顯示名稱與探險時長。
