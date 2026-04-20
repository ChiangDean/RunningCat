# 背包系統 — Frontend GDD (Godot)

## 1. Feature Summary

背包功能以 Overlay 形式開啟，讓玩家統一查看當前持有的所有資源。  
分為三個區塊，依序顯示：

- **貨幣**：Gold、鑽石、衝撞幣
- **票券**：競技場券、收益券(1小時)、各地下城門票（依地下城數量動態產生）
- **道具**：所有消耗品（貓糧、特殊乾糧、誘捕籠、屎堆、回憶碎片、鬍鬚碎片）

所有資料來自 Bootstrap，**不需額外 API 呼叫**。

---

## 2. Scene / Node 結構

```
BackpackScene (Control)
├── Background (TextureRect)               使用 "shop" 背景
├── Dim (ColorRect)                        半透明遮罩
├── TopMask (ColorRect)                    頂部遮罩
├── BackPanel (PanelContainer)             左下角返回按鈕
│   └── BackButton                         "返回" → return_to_battle()
├── ContentPanel (PanelContainer)          主內容面板
│   └── MarginContainer (18px all)
│       └── ContentBox (VBoxContainer)
│           ├── TitleLabel                 "背包"（FONT_SIZE_DISPLAY）
│           ├── HSeparator
│           └── ScrollContainer           (InertialScroller attached)
│               └── SectionsVBox (VBoxContainer, separation=16)
│                   ├── [貨幣區塊]
│                   ├── HSeparator
│                   ├── [票券區塊]
│                   ├── HSeparator
│                   └── [道具區塊]
```

### 區塊結構（三個區塊共用）

```
SectionBlock (VBoxContainer)
├── SectionHeader (HBoxContainer)
│   ├── SectionLabel                       "貨幣" / "票券" / "道具"
│   └── HSeparator (SIZE_EXPAND_FILL)
└── ItemGrid (GridContainer, columns=3)
    └── [ItemCard] × N
```

### ItemCard

```
ItemCard (PanelContainer)                  make_card_panel(accent)
└── MarginContainer (10px all)
    └── VBoxContainer (separation=4)
        ├── CenterContainer
        │   └── IconRect (TextureRect, 52×52)   數量=0 時 modulate 灰化
        ├── NameLabel                            置中，FONT_SIZE_LABEL，多行自動換行
        └── QtyLabel                             置中，FONT_SIZE_BODY
```

**ItemCard 顏色規則：**

| 狀態 | 邊框顏色 | 圖示 | 名稱 | 數量 |
|------|---------|------|------|------|
| 持有 (qty > 0) | `CARD_BORDER` | 正常 | 正常 | `CARD_BORDER` 色 |
| 未持有 (qty = 0) | `Color(0.35, 0.33, 0.28, 0.70)` | 灰化 0.55 | 灰色 0.55 | 灰色 0.45 |

---

## 3. 資料來源對應表

### 貨幣區塊

| 顯示名稱 | GameState 欄位 | 圖示路徑 |
|---------|--------------|---------|
| 金幣 | `player_data.gold` | `catalog/currency/gold` |
| 鑽石 | `player_data.diamonds` | `catalog/currency/diamonds` |
| 衝撞幣 | `player_data.trap_points` | `catalog/currency/trap_points` |

### 票券區塊

| 顯示名稱 | GameState 欄位 | 圖示路徑 |
|---------|--------------|---------|
| 競技場券 | `arena_overview_data.get("tickets", 0)` | `catalog/arena/bronze_1` |
| 收益券(1小時) | `get_party_cheer_coupon_count()` | `catalog/consumable/party_cheer_coupon` |
| 各地下城門票 | `dungeon_overview_data[i].remainingTicketCount` | `catalog/dungeon/{key}` |

收益券(1小時) 為固定票券項目，圖示資產解析到 `assets/sprites/ui/rewards/party_cheer_coupon.svg`。

地下城門票依 `dungeon_overview_data` 陣列動態產生，displayName 直接取自資料，key 對應圖示（cat_food / diamond / whisker）。

### 道具區塊

| 顯示名稱 | GameState 欄位 | 圖示路徑 |
|---------|--------------|---------|
| 貓糧 | `player_data.cat_food` | `catalog/consumable/cat_food` |
| 特殊乾糧 | `player_data.special_cat_food` | `catalog/consumable/special_cat_food` |
| 誘捕籠 | `player_data.trap_cages` | `catalog/consumable/trap_cages` |
| 屎堆 | `player_data.poop_count` | `catalog/consumable/poop_count` |
| 回憶碎片 | `player_data.memory_shards` | `catalog/consumable/memory_shards` |
| 鬍鬚碎片 | `player_data.whisker_shards` | `catalog/consumable/whisker_shards` |

---

## 4. User Flow

```
點擊底部導航「背包」按鈕
  → _toggle_overlay_scene("res://scenes/BackpackScene.tscn")
  → BackpackScene._ready()
      → OverlaySceneChrome.build(show_dock: false)    ← 只顯示返回按鈕，無分頁列
      → _build_content(content_box)
          → 依序建立三個區塊（貨幣→票券→道具）
          → 每個 ItemCard 從 GameState 讀取數量，數量=0 呈現灰化狀態

點擊「返回」
  → SceneNavigator.return_to_battle()
```

---

## 5. API Calls Summary

本功能不需要任何額外 API 呼叫。  
所有資料均在 Bootstrap 時載入至 GameState：

| 資料 | Bootstrap 欄位 |
|------|--------------|
| 貨幣 | `gold`, `diamonds`, `trapPoints` |
| 消耗品 | `catFood`, `specialCatFood`, `trapCages`, `poopCount`, `memoryShards`, `whiskerShards` |
| 收益券資料 | `partyCheerCouponCount` |
| 競技場資料 | `arenaData` → `arena_overview_data` |
| 地下城資料 | `dungeons` → `dungeon_overview_data` |

---

## 6. Navigation Entry Point

入口位於 BattleScene 底部導航列（第 6 個按鈕）：

```gdscript
# scripts/battle/battle_scene.gd
var nav_items: Array = [
    ...
    [UiText.NAV_BACKPACK, "res://scenes/BackpackScene.tscn", _on_nav_backpack],
]
```

---

## 7. 檔案清單

| 檔案 | 說明 |
|------|------|
| `scenes/BackpackScene.tscn` | 場景入口（掛載腳本） |
| `scripts/backpack/backpack_scene.gd` | 主場景邏輯，負責建構所有 UI |
| `scripts/ui/ui_text.gd` | 新增 `NAV_BACKPACK`、`BACKPACK_*` 文字常數 |
| `scripts/battle/battle_scene.gd` | 新增第 6 個導航按鈕及 `_on_nav_backpack()` 回呼 |

---

## 8. 注意事項

- **未來新增消耗品**：目前道具區塊硬編碼對應 `player_data` 欄位。若後端新增消耗品類型，前端需同步更新 `_build_consumable_section()` 中的對應表，並在 PlayerData 新增欄位。若要徹底解耦，可改為後端 Bootstrap 回傳 `consumableInventory: [{id, quantity}]` 陣列（目前為 Plan A 簡易版）。
- **地下城票券**：依 `dungeon_overview_data` 動態產生，新增地下城類型時前端自動支援，不需改動程式碼。
- **票券數量時效性**：由於資料來自 Bootstrap，若玩家在背包開啟期間消耗票券（如進行競技場對戰），背包數字不會即時更新。關閉後重開才會反映最新狀態（與其他資源顯示邏輯一致）。
