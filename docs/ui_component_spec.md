# MeowPartyDash UI Component Spec

> 本文件定義前端所有 UI 元件的使用規範，開發新功能時請以此為依據。
> 最後更新：2026-04-15

---

## 目錄

1. [按鈕系統](#1-按鈕系統)
2. [對話框 / Dialog](#2-對話框--dialog)
3. [Toast 通知](#3-toast-通知)
4. [導覽列 / 選單](#4-導覽列--選單)
5. [面板 / 卡片樣式](#5-面板--卡片樣式)
6. [稀有度顏色](#6-稀有度顏色)
7. [顏色常數](#7-顏色常數)

---

## 1. 按鈕系統

### 使用方式

```gdscript
UiPalette.apply_button_kind(button, "confirm")   # 語意別名
UiPalette.apply_button_kind(button, "primary")   # 顏色名稱（等同 confirm）
```

語意別名與顏色名稱**完全等價**，兩種寫法均有效。建議新代碼使用語意別名。

---

### 按鈕種類對照表

| 語意別名 | 顏色名稱 | 外觀 | 使用情境 |
|---------|---------|------|---------|
| `confirm` | `primary` | 金黃色 | **主要操作**：確認、購買、送出、開始戰鬥、抽卡 |
| `cancel` | `secondary` | 棕褐色 | **次要操作**：取消、返回次一步、不買 |
| `neutral` | `rank` | 深棕色 | **中性操作**：切換隊伍面板、查看詳情、免費抽（已使用） |
| `info` | `info` | 深灰色 | **純資訊**：顯示說明、排名加成資訊（無明確方向） |
| `destruct` | `danger` | 深紅色 | **危險操作**：重置點數、重置強化、取消訂單 |
| `remove` | `minus` | 深灰色（小） | **數量減少**：購買數量 `-` |
| `add` | `plus` | 橄欖棕色（小） | **數量增加**：購買數量 `+`、新增技能點 `+` |

---

### 現有場景按鈕對照

#### ActivityScene
| 按鈕文字 | 種類 | 說明 |
|---------|------|------|
| 各活動行動（進入副本等） | `confirm` | 主要進入動作 |

#### ArenaScene（競技場）
| 按鈕文字 | 種類 | 說明 |
|---------|------|------|
| 出戰 / 挑戰（有門票） | `confirm` | 主要挑戰動作 |
| 出戰（無門票） | `neutral` | 門票不足時降級顯示 |
| 換一批對手 | `cancel` | 次要操作 |
| 切換隊伍面板 | `neutral` | 展開/收合資訊 |
| 隊伍說明 `?` | `neutral` | 資訊類 |
| 領取獎勵 | `confirm` | 主要操作 |

#### DungeonSceneUI（副本）
| 按鈕文字 | 種類 | 說明 |
|---------|------|------|
| 挑戰 第 N 層 | `confirm` | 主要挑戰操作 |
| 掃蕩 第 N 層 | `neutral` | 快速掃蕩（次主要） |
| 廣告送門票（兩者皆顯示） | 依情境 | 與上方一致 |

#### GachaScene（扭蛋）
| 按鈕文字 | 種類 | 說明 |
|---------|------|------|
| 抽 N 次 | `confirm` | 主要抽卡動作 |
| 免費抽（可用） | `neutral` | 已重置但非主要消費流程 |
| 免費抽（已使用） | `neutral` | 顯示冷卻，disabled |

#### ShopScene（商店）
| 按鈕文字 | 種類 | 說明 |
|---------|------|------|
| 購買（道具包、競技門票） | `confirm` | 主要購買動作 |
| 確認購買（確認視窗內） | `confirm` | 確認送出 |
| 取消（確認視窗內） | `destruct` | 放棄此次購買 |
| 分頁切換（永久 / 限定） | `confirm` / 無樣式 | 已選中 / 未選中 |
| 數量 `+` | `add` | 增加購買數量 |
| 數量 `-` | `remove` | 減少購買數量 |

#### EnhanceSceneUI（強化）
| 按鈕文字 | 種類 | 說明 |
|---------|------|------|
| 升等（食物） | `neutral` | 消費貓糧升等 |
| 升滿（食物） | `neutral` | 一鍵最大升等 |
| 升階（排名） | `neutral` | 消費素材升階 |
| 排名資訊 `?` | `info` | 說明型 |
| 加點 `+` | `add` | 增加特殊屬性點 |
| 套用特殊點數 | `confirm` | 確認套用 |
| 重置特殊點數 | `destruct` | 危險，需確認 |
| 重置強化 | `destruct` | 危險，需確認 |

#### ConfigScene（隊伍設定）
| 按鈕文字 | 種類 | 說明 |
|---------|------|------|
| 儲存隊伍 | `confirm`（自訂色） | 主要儲存動作 |
| 延遲設定 | 自訂棕色 | 依槽位是否填入而異 |
| 排序：等級 / 排名 | 無 UiPalette | 小型切換鈕 |
| 移除貓咪 `－` | 自訂紅色 | 危險型小按鈕 |

---

## 2. 對話框 / Dialog

使用 `DialogManager`（Autoload）。

### 何時使用 Dialog

- 玩家**需要確認才能繼續**的操作（購買、重置、解散）
- 需要顯示**重要資訊說明**（排名加成、規則說明）
- **錯誤訊息**（API 失敗、資料載入失敗）

> 輕量操作反饋（購買成功、道具使用成功）請改用 **Toast**，不要用 Dialog。

### API

```gdscript
# 單純說明（有關閉按鈕）
DialogManager.show_info("標題", "內容", on_close_callable, "medium")

# 自訂 Node 內容
DialogManager.show_info_node("標題", content_control, on_close_callable, "medium")

# 確認對話框（兩個按鈕）
DialogManager.show_confirm("標題", "內容", on_confirm, on_cancel, "確認", "取消", "medium")
```

### 寬度規格

| 參數 | 寬度 | 適用 |
|------|------|------|
| `"small"` | 480px | 簡短確認訊息 |
| `"medium"` | 560px | 一般說明 / 確認（預設） |
| `"large"` | 640px | 含列表或圖片說明 |
| `"xlarge"` | 700px | 複雜內容 |

### 現有使用場景

| 場景 | 觸發時機 | 種類 |
|------|---------|------|
| 競技場 | 挑戰確認 | `show_confirm` |
| 競技場 | 排名加成說明 | `show_info` |
| 商店 | 購買確認 | `show_confirm` |
| 商店 | 購買失敗 | `show_info` |
| 扭蛋 | 資料載入失敗 | `show_info` |
| 強化 | 升階確認 | `show_confirm` |
| 強化 | 重置確認 | `show_confirm` |
| 設定 | 儲存失敗 | `show_info` |

---

## 3. Toast 通知

使用 `ToastManager`（Autoload）。

### 何時使用 Toast

- 操作**成功**的輕量反饋（購買成功、道具已使用、設定已儲存）
- **非阻斷性錯誤**（網路逾時，可以繼續操作）
- **提示資訊**（已達上限、冷卻中、已複製）

### API

```gdscript
ToastManager.success("購買成功")
ToastManager.success("已領取獎勵", "競技場月票 x1")   # 附說明文字

ToastManager.error("購買失敗，請稍後再試")
ToastManager.error("網路錯誤", "錯誤碼：403")

ToastManager.hint("免費抽卡已重置")
ToastManager.hint("今日已達購買上限")
```

### 視覺規格

| 種類 | 顏色 | 圖示 | 自動消失 |
|------|------|------|---------|
| `success` | 綠色 | ✓ | 3 秒 |
| `error` | 紅色 | ✕ | 3 秒 |
| `hint` | 黃色 | ！ | 3 秒 |

- 從**畫面頂部**滑入（Back 動畫，0.25 秒）
- 自動淡出（0.20 秒）
- 多則 Toast 自動排隊依序顯示

### Dialog vs Toast 判斷

| 情境 | 使用 |
|------|------|
| 購買成功 | Toast success |
| 購買失敗（API 錯誤） | Toast error |
| 購買失敗（餘額不足） | Dialog info（需引導玩家充值） |
| 需要玩家確認才執行 | Dialog confirm |
| 重要規則說明 | Dialog info |
| 操作無效（已達上限） | Toast hint |

---

## 4. 導覽列 / 選單

### 主導覽列（底部 Dock）

使用 `SceneSubmenuBar.build()` 或透過 `OverlaySceneChrome.build()` 的 `dock_items` 參數傳入。

**使用時機**：場景內有 2 個以上的主要分頁（例如：永久池 / 限定池、掃蕩 / 挑戰）。

```gdscript
OverlaySceneChrome.build(self, "background_key", _on_back, {
    "dock_items": [
        {"key": "tab_a", "label": "分頁A"},
        {"key": "tab_b", "label": "分頁B"},
    ],
    "show_dock": true,
    "active_key": "tab_a",
    "button_pressed": _on_tab_pressed,
})
```

### 側邊欄子選單

使用 `SceneSecondarySubmenu.build()`。

**使用時機**：場景內有垂直分類列表（例如商店分類），左側固定選單，右側顯示內容。

### 二次確認視窗

使用 `DialogManager.show_confirm()`。  
**使用時機**：玩家操作有不可逆後果（消費貨幣、重置資料）。

### 單次隨意點選取消視窗

目前由 `SceneNavigator` 管理的 Overlay 層處理（點擊背景返回）。  
未來可考慮加入 `LightboxOverlay` 元件統一管理。

---

## 5. 面板 / 卡片樣式

### 主面板（Scene Content Panel）

```gdscript
OverlaySceneChrome.make_panel_style(
    OverlaySceneChrome.PANEL_FILL,   # Color(0.08, 0.07, 0.08, 0.94)
    OverlaySceneChrome.PANEL_BORDER, # Color(0.80, 0.67, 0.42, 0.95)
    18                               # 圓角半徑
)
```

### 卡片（Card）

```gdscript
OverlaySceneChrome.make_card_panel()                   # 預設深灰卡片
OverlaySceneChrome.make_card_panel(accent_color)       # 自訂邊框色
OverlaySceneChrome.make_card_panel(accent, fill, 12)   # 完整自訂
```

預設值：
- `fill`：`Color(0.16, 0.15, 0.18, 0.96)` — 深灰
- `border`：`Color(0.50, 0.43, 0.30, 0.92)` — 暗金
- `radius`：14px

### 不要做的事

- **不要**在場景內自行定義 `_make_panel_style()`，請呼叫 `OverlaySceneChrome.make_panel_style()`
- **不要**在場景內自行實作 `_apply_button_palette()`，請呼叫 `UiPalette.apply_button_palette()`

---

## 6. 稀有度顏色

使用 `GameConstants`（`class_name`，全域可用）。

```gdscript
# 從 API rarityType 字串取得顏色
var color: Color = GameConstants.get_rarity_color_from_string("Rare")

# 從 enum 取得顏色
var color: Color = GameConstants.get_rarity_color(GameConstants.Rarity.LEGENDARY)
```

### 對照表

| Rarity enum | API 字串 | 顏色 | 用途 |
|------------|---------|------|------|
| `COMMON` | `"Common"` | 灰白 `(0.78, 0.78, 0.78)` | 普通貓、普通道具 |
| `RARE` | `"Rare"` | 藍色 `(0.43, 0.73, 1.0)` | 稀有貓 |
| `EPIC` | `"Epic"` | 紫色 `(0.78, 0.50, 1.0)` | 史詩貓 |
| `LEGENDARY` | `"Legendary"` | 金色 `(1.0, 0.78, 0.36)` | 傳說貓 |

> 若 API 回傳 `rarityColor`（`#RRGGBB` 格式），優先使用 API 色碼；
> 否則 fallback 至 `GameConstants.get_rarity_color_from_string(rarityType)`。

---

## 7. 顏色常數

### OverlaySceneChrome 顏色

| 常數 | 值 | 用途 |
|------|-----|------|
| `PANEL_FILL` | `(0.08, 0.07, 0.08, 0.94)` | 主面板背景 |
| `PANEL_BORDER` | `(0.80, 0.67, 0.42, 0.95)` | 主面板邊框（金色） |
| `CARD_FILL` | `(0.16, 0.15, 0.18, 0.96)` | 卡片背景 |
| `CARD_BORDER` | `(0.50, 0.43, 0.30, 0.92)` | 卡片邊框（暗金） |
| `MUTED_TEXT_COLOR` | `(0.90, 0.88, 0.82, 0.92)` | 次要文字 |
| `TITLE_TEXT_COLOR` | `(0.99, 0.97, 0.90, 1.0)` | 標題文字 |

### UiPalette 按鈕顏色

| 按鈕種類 | BG 色 | FG 色 |
|---------|-------|-------|
| `confirm` / `primary` | 金黃 `(0.94, 0.77, 0.39)` | 深棕 `(0.16, 0.11, 0.05)` |
| `cancel` / `secondary` | 棕褐 `(0.63, 0.46, 0.20)` | 米白 `(0.98, 0.95, 0.88)` |
| `neutral` / `rank` | 深棕 `(0.30, 0.22, 0.10)` | 米白 |
| `info` | 深灰 `(0.22, 0.19, 0.17)` | 米白 |
| `destruct` / `danger` | 深紅 `(0.42, 0.18, 0.16)` | 米白 |
| `remove` / `minus` | 深灰 `(0.24, 0.21, 0.18)` | 米白 |
| `add` / `plus` | 橄欖棕 `(0.55, 0.41, 0.16)` | 亮米 `(1.0, 0.97, 0.86)` |

---

*如有新場景或新元件，請同步更新本文件的「現有使用場景」段落。*
