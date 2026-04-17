# 24. 屬性數值總覽面板（Stats Panel）

> 更新日期：2026-04-17
> 前端功能文件

---

## 概述

「屬性數值總覽」面板提供玩家一個集中檢視所有屬性加成來源的入口，讓玩家能清楚了解當前陣容的完整數值狀態。面板透過主戰鬥畫面右側的「數值」快捷按鈕開啟，以分頁方式呈現各加成來源的詳細數值。

---

## 入口位置

- **場景**：主戰鬥畫面（`battle_scene.gd`）
- **按鈕標籤**：數值
- **位置**：右側動作堆疊（Action Stack）第五個按鈕，固定錨點於 `(ACTION_STACK_X, ACTION_STACK_Y + (ACTION_STACK_H + 10) × 4)`
- **行為**：點擊切換面板顯示 / 隱藏；面板顯示時會呼叫 `refresh()` 更新數據

---

## 面板佈局

面板為全螢幕覆蓋層（`Control.PRESET_FULL_RECT`），包含：

1. **半透明背景**（`ColorRect`）：滑鼠左鍵點擊可關閉面板
2. **內容面板**（`PanelContainer`）：
   - 上偏移：96px（避開頂部 HUD）
   - 下偏移：120px（避開底部導覽列）
   - 左右偏移：±16px

### 面板內部結構

```
[標題列] 屬性數值總覽              [✕ 關閉]
[分頁列] 全部 | 技能 | 裝備 | 回憶 | 寶藏 | 等級
[ScrollContainer]
  └─ [內容區塊 VBoxContainer]
       └─ [各加成類別卡片]
```

---

## 分頁說明

### Tab 1：全部（all）

彙整所有加成來源的總合，包含以下區塊：

| 區塊標題 | 內容 |
|----------|------|
| 全域戰鬥加成 | 裝備 + 回憶 + 寶藏 + 鏟屎官等級等所有戰鬥屬性加成的合計 |
| 非戰鬥效果 | 特殊技能中的非戰鬥效果（如寶箱機率、每日掉落等） |
| 便當收益 | 所有來源的閒置便當加成合計 |
| 特殊技能效果 | 特殊技能的戰鬥加成彙整 |
| 角色被動（角色名稱）| 每位上場角色的被動技能效果（依等級縮放後的數值） |

### Tab 2：技能（ability）

來源：`GameState.get_special_ability_summary()`

顯示所有已解鎖特殊技能的加成效果，依戰鬥效果與非戰鬥效果分組。

### Tab 3：裝備（equipment）

來源：`GameState.get_equipment_bonuses()`

顯示目前已裝備物品提供的所有屬性加成，依屬性類型彙整顯示。

### Tab 4：回憶（memory）

來源：`GameState.get_memory_bonuses()`

顯示已裝備回憶卡提供的所有屬性加成。

### Tab 5：寶藏（treasure）

來源：`GameState.get_treasure_effects()`、`GameState.get_treasure_combat_bonuses()`、`GameState.get_treasure_idle_poop_bonus()`

顯示寶藏系統提供的戰鬥加成、非戰鬥效果及閒置便當加成。

### Tab 6：等級（level）

來源：`GameState.player_data.scooper_level` 及對應等級成長表

顯示鏟屎官升級帶來的屬性加成效果。

---

## 角色被動顯示規則

- 來源：`GameState.player_team`（當前上場角色 ID 陣列）
- 每位上場角色各有一個獨立卡片，標題格式為「角色被動（{角色名稱}）」
- 被動效果依角色當前等級與星級縮放顯示數值
- 每位角色所有被動技能的效果均逐條列出

---

## 數值顯示格式

| 類型 | 格式範例 |
|------|----------|
| 平值加成（flat） | 攻擊力 +50 |
| 百分比加成（percent） | 攻擊加成 +12% |
| 無加成 | 無加成 |

複數相同屬性的加成（如多件裝備均提供攻擊力）在「全部」Tab 中合併顯示，在各分類 Tab 中按來源列出後合算顯示。

---

## 技術實作

### 相關檔案

| 檔案路徑 | 說明 |
|----------|------|
| `scripts/battle/StatsPanel.gd` | 面板主體邏輯 |
| `scripts/battle/battle_scene.gd` | 按鈕建立與面板掛載 |
| `scripts/ui/ui_text.gd` | 面板所有文字常數 |

### 主要類別：`StatsPanel`

```gdscript
class_name StatsPanel
extends Control
```

- `_ready()`：設定全螢幕錨點，取得 GameState 節點，呼叫 `_build_panel()`
- `refresh()`：清除並重建當前分頁內容
- `_rebuild_content()`：依 `_current_tab` 呼叫對應 build 方法
- `_build_all_tab()`：彙整所有加成來源，建立「全部」分頁內容
- `_build_ability_tab()` / `_build_equipment_tab()` / ... 各分頁建立方法
- `_build_team_passive_sections()`：逐一讀取 `player_team` 角色資料，顯示被動效果
- `_aggregate(bonuses: Array)`：將加成陣列依屬性→目標分組加總，回傳合併後的顯示資料

### UiText 常數（`scripts/ui/ui_text.gd`）

```gdscript
const STATS_PANEL_TITLE := "屬性數值總覽"
const STATS_PANEL_CLOSE := "✕"
const STATS_BTN_LABEL := "數值"
const STATS_TAB_ALL := "全部"
const STATS_TAB_ABILITY := "技能"
const STATS_TAB_EQUIPMENT := "裝備"
const STATS_TAB_MEMORY := "回憶"
const STATS_TAB_TREASURE := "寶藏"
const STATS_TAB_LEVEL := "等級"
const STATS_SECTION_ALL_COMBAT := "全域戰鬥加成"
const STATS_SECTION_NONCOMBAT := "非戰鬥效果"
const STATS_SECTION_POOP := "便當收益"
const STATS_SECTION_ABILITY := "特殊技能效果"
const STATS_SECTION_EQUIPMENT := "裝備加成"
const STATS_SECTION_MEMORY := "回憶加成"
const STATS_SECTION_TREASURE := "寶藏加成"
const STATS_SECTION_LEVEL := "鏟屎官等級"
const STATS_SECTION_PASSIVE_FORMAT := "角色被動（%s）"
const STATS_SECTION_EMPTY := "無加成"
```

---

## 開啟 / 關閉行為

| 操作 | 行為 |
|------|------|
| 點擊「數值」按鈕 | 切換面板顯示狀態，顯示時呼叫 `refresh()` |
| 點擊半透明背景 | 關閉面板 |
| 點擊 ✕ 按鈕 | 關閉面板 |

---

## 相關系統

- [鏟屎官系統](12_scooper.md)：特殊技能、裝備、回憶、寶藏、等級資料來源
- [屬性系統](02_attributes.md)：屬性類型定義
- [前端架構](18_frontend_architecture.md)：UI 元件規範
