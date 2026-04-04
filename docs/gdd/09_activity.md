# 九、活動系統

## 9-1 活動入口

主畫面底部導覽列：**配置 ／ 強化 ／ 活動 ／ 商店**

點擊「活動」進入活動頁，目前包含：

| 功能 | 狀態 |
|------|------|
| 地下城 | ✅ 實作 |
| 競技場 | 🔒 待開放（移至活動頁） |

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

```
地下城列表
  └─ [掃蕩 Lv.X]     → 秒拿 Lv.X 獎勵，消耗一張卷（須已通關至少 Lv.1）
  └─ [挑戰 Lv.X+1]   → 進入地下城戰鬥
        ├─ 勝利：消耗一張卷 → 更新最高紀錄 → 發放獎勵 → 返回列表
        └─ 失敗：不消耗卷 → 返回列表
```

### 敵人難度公式

```
stats(level) = base_stat × difficulty_multiplier^(level - 1)
```

各地下城的 `base_hp`、`base_atk`、`base_def`、`difficulty_multiplier` 均在 Config 設定。

### 獎勵公式

| 地下城 | 普通乾糧 | 特殊乾糧 | 鑽石 | 誘捕籠 | 鬍鬚碎片 |
|--------|---------|---------|------|--------|---------|
| 乾糧地下城 | 關卡 × 5 | 關卡 × 1 | — | — | — |
| 鑽石地下城 | — | — | 關卡 × 2 | `round(關卡/5 + 0.5)` | — |
| 鬍鬚地下城 | — | — | 關卡 × 2 | — | `round(關卡/10 + 0.5)` |

Config 中對應欄位：`cat_food_per_level`、`special_cat_food_per_level`、`diamonds_per_level`、`trap_cage_divisor`、`whisker_shard_divisor`（divisor=0 表示不給該獎勵）

### 誘捕籠道具

- 類型：消耗品，存放於 `player_data.trap_cages`
- 來源：鑽石地下城、未來其他活動
- 使用：在誘捕籠（GachaScene）頁面點擊「使用誘捕籠道具」，消耗 1 個執行 1 抽

### 通用鬍鬚碎片

- 存放於 `player_data.whisker_shards`
- 來源：鬍鬚地下城、未來其他活動
- 使用方式：待強化系統支援通用碎片指定貓咪後開放

---

## 9-3 Config 設定位置

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
