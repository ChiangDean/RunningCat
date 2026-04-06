# 十二、鏟屎官系統

## 12-1 導覽結構

主畫面底部導覽列順序調整為：

| 順序 | 按鈕 |
|------|------|
| 1 | 鏟屎官（新增） |
| 2 | 配置 |
| 3 | 強化 |
| 4 | 活動 |
| 5 | 商店 |

鏟屎官頁面內有四個 Tab：

| Tab | 說明 |
|-----|------|
| 鏟屎官 | 等級、特殊能力、裝備 |
| 回憶 | 貓咪照片收藏與屬性加成 |
| 寶藏 | 購買/活動取得的特殊道具 |
| 成就 | 大小成就與領取獎勵 |

---

## 12-2 掛機系統

### 計算方式
- 離線也繼續計算
- 最大累積上限（預設 8 小時，由 JSON 設定）
- **以分鐘為最小計算單位**：不足一分鐘的秒數不計入當次領取，保留至下次
  - 例：累積 20 分鐘 07 秒 → 領取 20 分鐘的獎勵，07 秒繼續累積
- 回到遊戲後一次性領取累積整分鐘的產出

### 掛機產出

| 產出 | 說明 |
|------|------|
| 金幣 | 新貨幣，主要用於鏟屎官系統 |
| 屎堆 | 可點擊鏟除，觸發鏟屎互動 |
| 貓糧 | 現有道具 |
| 鑽石 | 現有道具 |
| 鬍鬚 | 現有品階道具 |

### 產出速率

速率以 /h 標示，實際依完整分鐘數計算（`floor(速率 × 分鐘數 / 60)`）。

#### 基礎速率

| 產出 | 基礎速率 |
|------|---------|
| 金幣 | 1000 / h |
| 屎堆 | 5 / h |
| 貓糧 | 5 / h |
| 鑽石 | 10 / h |
| 鬍鬚 | 1 / h |

#### 關卡加成（當前推關進度）

| 條件 | 加成 |
|------|------|
| 每滿 50 關 | 金幣 +100/h、屎堆 +2/h、貓糧 +2/h、鑽石 +2/h |
| 每滿 150 關 | 鬍鬚 +1/h |

#### 鏟屎官等級加成

| 條件 | 加成 |
|------|------|
| 每 1 級 | 金幣 +(等級×1000)/h、屎堆 +(等級×5)/h、貓糧 +(等級×5)/h、鑽石 +(等級×10)/h |

（鬍鬚無鏟屎官等級加成）

### 領取按鈕行為

- 按鈕名稱：「🪣 貓砂盆」，位於主畫面頂部
- **不足一分鐘時**：按鈕 disabled，顯示「🪣 乾淨貓砂盆」
- **滿一分鐘以上**：按鈕 enabled，顯示累積時長，格式 `🪣 清理貓砂盆 HH:MM:SS`
  - 例：「🪣 清理貓砂盆 05:32:07」→ 可領取 5 小時 32 分鐘的獎勵，07 秒繼續累積
- 按鈕每秒更新時長顯示

### 鏟屎互動
- 玩家回到遊戲後，可對累積的屎堆逐一鏟除（每次消耗一個屎堆）
- 每次鏟屎掉落（機率由 JSON 設定）：

| 產出 | 基礎機率 | 鏟屎官等級加成 |
|------|---------|--------------|
| 鏟屎官 EXP（1 點） | 100% | — |
| 回憶碎片 | 0.01% | 每 2 級 +0.01% |
| 鬍鬚 | 0.02% | 每 1 級 +0.01% |

---

## 12-3 鏟屎官 Tab

顯示：鏟屎官等級、當前經驗值進度、特殊能力列表、裝備列表

### 頁面捲動互動

- 「鏟屎官」Tab 與「回憶」Tab 內的長列表皆使用 **垂直 ScrollContainer + 慣性卷軸**
- 互動方式：
  - 滑鼠左鍵拖曳 / 觸控上下拖曳可捲動列表
  - 放手後保留慣性，逐步減速停止
  - 捲動時顯示垂直捲軸，停止後自動淡出
- 慣性卷軸輸入捕捉需以 **ScrollContainer 範圍** 為準，不能只依賴空白區
  - 原因：列表卡片內通常包含按鈕、Label、Panel 等子節點，若僅監聽 `gui_input`，拖曳事件容易被子節點吃掉
  - 因此實作上應允許在列表子節點上開始拖曳，仍可觸發垂直卷動
- 目前套用範圍：
  - 鏟屎官 Tab：特殊能力列表、裝備列表
  - 回憶 Tab：回憶收藏列表
  - 寶藏 Tab：寶藏收藏列表

### 鏟屎官等級

- 透過鏟屎累積經驗值升等
- 等級越高，可購買的裝備種類越多
- 裝備升級上限不可超過鏟屎官當前等級
- 每級給予固定屬性加成（具體數值 TBD）

### 特殊能力

取得方式：課金貨幣 + 活動免費券（抽卡形式），或活動 / 成就直接給予

| 能力類型 | 效果 |
|---------|------|
| 掛機物品加成 | 掛機產出數量提升 X% |
| 掛機時間上限加成 | 最大累積時間延長 |
| 解鎖 2x 推BOSS速度 | 戰鬥動畫加速至 2x |
| 解鎖 3x 推BOSS速度 | 戰鬥動畫加速至 3x |
| 解鎖跳過按鈕 | 可直接跳過戰鬥動畫 |

### 裝備

- 每個裝備類別只有一個欄位（同類別無法重複裝備）
- 大多數裝備加成全隊，少數針對特定貓咪分類（如坦克系）
- 裝備解鎖等級由 JSON 設定，以下為預設規劃：

| 裝備名稱 | 加成目標 | 解鎖等級（預設） |
|---------|---------|--------------|
| 鏟子 | 全隊 | Lv.1 |
| 貓抓板 | 全隊 | Lv.1 |
| 逗貓棒 | 全隊 | Lv.2 |
| 梳毛棒 | 全隊 | Lv.3 |
| 相機 | 全隊 | Lv.4 |
| 暖墊 | 坦克系貓咪 | Lv.5 |
| 紙箱 | 全隊 | Lv.6 |
| 玩偶 | 全隊 | Lv.7 |

#### 裝備升級流程

1. 花費金幣「使用」裝備
2. 每次給予 0～3 經驗值（隨機，機率由 JSON 設定）
3. 升級上限 = 鏟屎官當前等級

#### 損壞狀態

- 每次使用有小機率損壞（機率由 JSON 設定）
- 損壞時：按鈕變色並顯示「損壞」字樣
- 需花費金幣修復後才可繼續使用
- **損壞期間該裝備不提供任何屬性加成**

#### 生病狀態

- 每次使用有小機率導致特定貓咪生病
- 生病期間**裝備無法升級**，需先就醫
- 就醫費用：金幣
- 就醫後恢復正常，裝備可繼續升級

---

## 12-4 回憶 Tab

- 掛機鏟屎時小機率獲得**回憶碎片**
- 碎片數量達到解鎖門檻後，玩家可**自由選擇**要解鎖哪個回憶
- 每個回憶為一張貓咪照片，解鎖後提供不同的屬性加成

### 存檔結構

- `memory_shards: int`
  - 共用回憶碎片數量
  - 來源為鏟屎掉落
- `unlocked_memory_ids: Array[String]`
  - 已解鎖回憶 ID 清單
  - 解鎖後永久保留，不重複解鎖

### 回憶設定 JSON

回憶資料由獨立 JSON 管理，建議欄位如下：

| 欄位 | 型別 | 說明 |
|------|------|------|
| `id` | String | 回憶唯一 ID |
| `name` | String | 回憶名稱 |
| `description` | String | 回憶文案 |
| `photo_path` | String | 圖片資源路徑；可為空字串 |
| `placeholder_color` | String | 未提供正式圖片時的卡片占位色 |
| `unlock_cost` | int | 解鎖所需回憶碎片數 |
| `bonus_target` | String | 加成目標，預設先支援 `all` |
| `bonus_stat` | String | 加成屬性 |
| `bonus_value` | float | 加成數值，使用百分比小數表示，例如 `0.03 = 3%` |

### 目前支援的回憶加成類型

- `atk_percent`
- `def_percent`
- `max_hp_percent`

以上三種與裝備系統共用同一套戰鬥加成格式，便於在戰鬥前統一疊加。

### 解鎖規則

- `memory_shards` 視為共用貨幣
- 當玩家碎片數量大於等於任一回憶 `unlock_cost` 時，可自由選擇解鎖哪張回憶
- 解鎖時**會消耗**對應數量的 `memory_shards`
- 解鎖成功後：
  - 該回憶 ID 加入 `unlocked_memory_ids`
  - 加成立即永久生效
- 已解鎖回憶不可再次解鎖，也不可重複消耗碎片

### UI 呈現規格

- 回憶頁顯示：
  - 目前持有回憶碎片數
  - 已解鎖數量 / 總回憶數
  - 回憶卡片列表
- 卡片狀態分為：
  - 已解鎖：顯示名稱、描述、加成內容，可查看詳情
  - 未解鎖：顯示深色遮罩 / 鎖定樣式 / 解鎖需求碎片數
- 未提供正式圖片時，可先使用占位色卡 + 文字完成版面
- 圖片正式資產補齊後，直接以 `photo_path` 載入並取代占位顯示

### 戰鬥套用範圍

- 回憶加成套用至所有主要戰鬥模式：
  - 推關戰鬥
  - 地下城戰鬥
  - 競技場戰鬥
- 套用時機與裝備相同，於貓咪進入戰鬥前一併計算
- 目前實作策略為：
  - 先整理裝備加成
  - 再整理回憶加成
  - 最終合併為統一的 combat bonuses 套入貓咪屬性

---

## 12-5 寶藏 Tab

- 目前主要取得來源為**商店 → 商城禮包 → 超值禮包**
- 購買後直接納入收藏，**不需裝備、不需啟用、立即生效**
- 可重複取得；若同一寶藏取得多次，**效果重複疊加**
- 與回憶不同，寶藏沒有碎片解鎖流程，也不顯示未持有項目

### 設計原則

- 寶藏定位為「可收藏、可重複取得、全域加成」的特殊道具
- 為了減少 UI 與存檔複雜度，這一版採用：
  - 玩家擁有的所有寶藏**全部同時生效**
  - 同一寶藏可重複取得，數量越多加成越高
  - UI 僅顯示已取得寶藏
  - 取得方式先以純文字描述，不做跳轉

### 目前取得流程

1. 進入商店
2. 點擊「商城禮包」
3. 進入分類「超值禮包」
4. 花費鑽石購買指定禮包
5. 禮包內的寶藏直接加入收藏
6. 收藏成功後立即套用掛機或戰鬥效果

### 存檔結構

- `treasures: Dictionary`
  - key = `treasure_id`
  - value 結構：
    - `quantity: int`
    - `latest_obtained_at: String`
- `bundle_purchase_counts: Dictionary`
  - key = `bundle_id`
  - value = 已購買次數 `int`

範例：

```json
{
  "treasures": {
    "moon_chime": {
      "quantity": 2,
      "latest_obtained_at": "2026-04-07 10:30:15"
    }
  },
  "bundle_purchase_counts": {
    "value_pack_moon_chime": 2
  }
}
```

### 寶藏設定 JSON

寶藏資料由 `data/default/treasure_config.json` 管理，建議欄位如下：

| 欄位 | 型別 | 說明 |
|------|------|------|
| `id` | String | 寶藏唯一 ID |
| `name` | String | 寶藏名稱 |
| `description` | String | 寶藏文案 |
| `source_text` | String | 取得方式描述文字 |
| `placeholder_color` | String | 卡片占位色 |
| `effects` | Array[Dictionary] | 效果清單，可放多條 |

單一 `effect` 結構：

| 欄位 | 型別 | 說明 |
|------|------|------|
| `target` | String | 作用目標，`all` 或指定貓咪類型 |
| `stat` | String | 效果類型 |
| `value` | float | 效果數值；百分比類一律用小數表示，例如 `0.05 = 5%` |

範例：

```json
{
  "id": "moon_chime",
  "name": "月鈴",
  "description": "晃動時會發出幾乎聽不見的細響，卻總能讓貓咪抓準致命一擊。",
  "source_text": "取得方式：商城禮包 / 超值禮包",
  "placeholder_color": "#7E8FB7",
  "effects": [
    { "target": "all", "stat": "crit_rate", "value": 0.04 },
    { "target": "all", "stat": "crit_damage", "value": 0.15 }
  ]
}
```

### 目前支援的 `target`

| target | 說明 |
|--------|------|
| `all` | 全隊生效 |
| `tank` | 只對 `cat_type = tank` 生效 |
| `speed` | 只對 `cat_type = speed` 生效 |
| `assassin` | 只對 `cat_type = assassin` 生效 |
| `defensive` | 只對 `cat_type = defensive` 生效 |

若未來新增新的貓咪類型，只要該 `cat_type` 已存在於貓咪資料，就可直接在寶藏 `target` 中使用。

### 目前支援的 `stat`

#### 戰鬥類

| stat | 說明 | 套用方式 |
|------|------|---------|
| `atk_percent` | 攻擊力百分比加成 | 戰鬥前直接乘上 `(1 + value)` |
| `def_percent` | 防禦力百分比加成 | 戰鬥前直接乘上 `(1 + value)` |
| `max_hp_percent` | 最大生命百分比加成 | 戰鬥前直接乘上 `(1 + value)` |
| `crit_rate` | 暴擊率加成 | 戰鬥中依機率判定是否暴擊，總上限 100% |
| `crit_damage` | 暴擊傷害加成 | 暴擊時追加到基礎暴傷倍率上 |
| `damage_reduction` | 減傷加成 | 最終受傷乘上 `(1 - value)`，總上限 90% |
| `cooldown_reduction` | 技能冷卻縮減 | 主動技能 CD 與 initial delay 一併縮短，總上限 50% |

#### 非戰鬥類

| stat | 說明 | 套用方式 |
|------|------|---------|
| `idle_poop_percent` | 掛機屎堆加成 | 掛機獎勵結算時只影響 `poop` 欄位 |

### 疊加規則

- 同一寶藏可重複取得
- 每取得一次，就再套用一次該寶藏內的全部 `effects`
- 不同寶藏之間也可同時疊加
- 上限規則：
  - `crit_rate`：100%
  - `damage_reduction`：90%
  - `cooldown_reduction`：50%
  - `idle_poop_percent`：目前不設硬上限，結算時直接乘上總倍率後取整數

### 商城禮包設定 JSON

商城禮包資料由 `data/default/shop_bundle_config.json` 管理，這一版先使用固定內容，不做隨機池。

分類資料：

| 欄位 | 型別 | 說明 |
|------|------|------|
| `id` | String | 分類 ID |
| `name` | String | 分類名稱 |

禮包資料：

| 欄位 | 型別 | 說明 |
|------|------|------|
| `id` | String | 禮包唯一 ID |
| `name` | String | 禮包名稱 |
| `category` | String | 所屬分類，目前為 `value_pack` |
| `description` | String | 禮包描述 |
| `diamond_cost` | int | 鑽石價格 |
| `purchase_limit` | int | 可購買次數上限；若未來需要無限購買，可改成負數表示無上限 |
| `rewards` | Array[Dictionary] | 禮包內容物 |

單一 `reward` 結構：

| 欄位 | 型別 | 說明 |
|------|------|------|
| `type` | String | 目前先支援 `treasure` |
| `id` | String | 寶藏 ID |
| `quantity` | int | 發放數量 |

範例：

```json
{
  "id": "value_pack_moon_chime",
  "name": "夜行暴擊組",
  "category": "value_pack",
  "description": "提高全隊暴擊率與暴擊傷害的泛用寶藏。",
  "diamond_cost": 420,
  "purchase_limit": 2,
  "rewards": [
    { "type": "treasure", "id": "moon_chime", "quantity": 1 }
  ]
}
```

### UI 呈現規格

- 寶藏頁顯示：
  - 已收藏種類數
  - 總持有件數
  - 寶藏卡片列表
- 每張卡片顯示：
  - 名稱
  - 數量
  - 描述
  - 取得方式
  - 最近取得時間
  - 效果列表
- 商城禮包頁顯示：
  - 分類切換列
  - 每個禮包的名稱、描述、價格、已購買次數 / 上限
  - 禮包內容物與各寶藏效果摘要

### 套用範圍

- 寶藏加成套用至所有玩家參與的主要戰鬥模式：
  - 推關戰鬥
  - 地下城戰鬥
  - 競技場進攻戰鬥
- 掛機部分目前先支援：
  - `idle_poop_percent`
- 套用時機：
  - 掛機獎勵在領取前即時計算
  - 戰鬥加成在玩家貓咪進入戰鬥前統一整理後套用

### 手動新增一個寶藏

1. 到 `data/default/treasure_config.json` 新增一筆 `items`
2. 填入 `id / name / description / source_text / placeholder_color / effects`
3. 確認 `effects[].target` 與 `effects[].stat` 都是目前支援的值
4. 若要讓玩家能從商城取得，再到 `data/default/shop_bundle_config.json` 新增一個對應禮包
5. 將 `rewards` 指向該寶藏 ID
6. 重新進遊戲後即可在商城禮包中購買

### 手動新增一個禮包

1. 到 `data/default/shop_bundle_config.json`
2. 在 `items` 中新增一筆禮包資料
3. 指定：
   - `category`
   - `diamond_cost`
   - `purchase_limit`
   - `rewards`
4. 若 `rewards` 內引用的寶藏 ID 不存在，禮包不應上線

### 若要擴充新的效果類型

若未來新增新的 `stat`，不要只改 JSON，至少要同步檢查：

1. `scripts/GameState.gd`
   - `apply_player_combat_bonuses()`
   - `_is_combat_bonus_stat()`
   - `get_treasure_idle_poop_bonus()` 或其他非戰鬥加成入口
2. `scripts/ScooperScene.gd`
   - `_format_treasure_effect()`
3. `scripts/ShopScene.gd`
   - `_format_effect_line()`
4. 若為戰鬥效果，可能還要改：
   - `scripts/battle/battle_simulator.gd`

否則會出現「JSON 有資料、UI 顯示不完整、實際沒生效」的狀況。

---

## 12-6 成就 Tab

- 分為小成就與大成就
- 完成條件後可手動領取獎勵（物品）
- 第一版只做「可由現況存檔直接重算」的門檻型成就，不做累積行為型成就
  - 例：鏟屎官等級、任意主子等級、任意主子品階、持有裝備數、推關進度、回憶解鎖數、主子持有數
- 大成就與小成就皆為手動領取，但大成就獎勵品質更高

### 存檔結構

- `achievement_states: Dictionary`
  - key = `achievement_id`
  - value 結構：
    - `completed: bool`
    - `claimed: bool`
    - `completed_at: String`
    - `claimed_at: String`

範例：

```json
{
  "achievement_states": {
    "small_scooper_lv_2": {
      "completed": true,
      "claimed": false,
      "completed_at": "2026-04-07 22:10:31",
      "claimed_at": ""
    }
  }
}
```

### 成就設定 JSON

成就資料由 `data/default/achievement_config.json` 管理，建議欄位如下：

| 欄位 | 型別 | 說明 |
|------|------|------|
| `id` | String | 成就唯一 ID |
| `name` | String | 成就名稱 |
| `category` | String | `small` 或 `big` |
| `condition_type` | String | 條件類型 |
| `condition_value` | int | 條件門檻 |
| `rewards` | Array[Dictionary] | 獎勵清單 |

單一 `reward` 結構：

| 欄位 | 型別 | 說明 |
|------|------|------|
| `type` | String | 獎勵類型 |
| `amount` | int | 數值型獎勵數量 |
| `id` | String | 特殊能力 / 寶藏 ID |
| `duplicate_compensation` | Dictionary | 特殊能力重複時的補償獎勵 |

### 第一版支援的 `condition_type`

| condition_type | 說明 |
|----------------|------|
| `scooper_level_reached` | 鏟屎官達到指定等級 |
| `any_cat_level_reached` | 任意主子達到指定等級 |
| `any_cat_rank_reached` | 任意主子達到指定品階 |
| `equipment_owned_count_reached` | 持有指定數量裝備 |
| `stage_reached` | 推關進度到達指定 Stage |
| `memory_unlocked_count_reached` | 解鎖指定數量回憶 |
| `owned_cat_count_reached` | 持有指定數量主子 |

### 第一版支援的 `reward.type`

- `gold`
- `diamonds`
- `cat_food`
- `special_cat_food`
- `whisker_shards`
- `memory_shards`
- `trap_cages`
- `special_ability`
- `treasure`

### 特殊能力重複補償規則

- 成就獎勵若為特殊能力，且玩家已先從活動 / 商城禮包 / 其他來源擁有該能力，則不重複發放
- 改為發放該成就 reward 中設定的 `duplicate_compensation`
- 第一版補償類型固定使用鑽石

### UI 呈現規格

- 成就頁面分成三區：
  - `大成就`
  - `小成就`
  - `已領取`
- `大成就` / `小成就` 排序規則：
  - 已達成但未領取 排最前
  - 未達成 排後面
- `已領取` 區塊固定放最底下，且**預設收合**
- 已達成但未領取時：
  - 成就卡片顯示可領取狀態
  - 成就 Tab 按鈕顯示提示
- 成就達成當下跳提示，提示玩家前往成就頁領取

### 領獎流程

1. 系統依現況重算成就是否達成
2. 若已達成且尚未領取，卡片顯示 `領取`
3. 玩家手動點擊後發放獎勵
4. 發放成功後：
   - `claimed = true`
   - 記錄 `claimed_at`
   - 該成就移入 `已領取` 區塊

### 第一版首批成就

#### 小成就

| ID | 名稱 | 條件 | 獎勵 |
|----|------|------|------|
| `small_scooper_lv_2` | 初出茅廬 | 鏟屎官達到 Lv.2 | 金幣 ×2000 |
| `small_scooper_lv_5` | 勤勞上手 | 鏟屎官達到 Lv.5 | 鑽石 ×80 |
| `small_cat_lv_10` | 愛貓之人 | 任意主子達到 Lv.10 | 貓糧 ×30 |
| `small_cat_lv_20` | 主子養成中 | 任意主子達到 Lv.20 | 特殊乾糧 ×8 |
| `small_cat_rank_5` | 鬍鬚小達人 | 任意主子達到 +5 品階 | 鬍鬚 ×40 |
| `small_equipment_3` | 三件套入門 | 持有 3 件裝備 | 金幣 ×8000 |
| `small_stage_10` | 初探領地 | 推關進度到達 Stage 10 | 鑽石 ×120 |
| `small_memory_1` | 第一張回憶 | 解鎖 1 張回憶 | 回憶碎片 ×10 |
| `small_owned_cat_3` | 貓口增員 | 持有 3 隻主子 | 誘捕籠 ×2 |

#### 大成就

| ID | 名稱 | 條件 | 獎勵 |
|----|------|------|------|
| `big_scooper_lv_8` | 老練鏟屎官 | 鏟屎官達到 Lv.8 | 特殊能力 `idle_time_extension` |
| `big_stage_50` | 穩定推進 | 推關進度到達 Stage 50 | 特殊能力 `boss_speed_2x` |
| `big_stage_150` | 高速推進 | 推關進度到達 Stage 150 | 特殊能力 `boss_speed_3x` |
| `big_stage_300` | 瞬間收工 | 推關進度到達 Stage 300 | 特殊能力 `battle_skip` |
| `big_cat_rank_10` | 品階達人 | 任意主子達到 +10 品階 | 寶藏 `bastion_whisker_knot` ×1 |
| `big_memory_3` | 回憶收藏家 | 解鎖 3 張回憶 | 寶藏 `moon_chime` ×1 |
| `big_equipment_8` | 裝備控 | 持有 8 件裝備 | 寶藏 `spring_paw_clockwork` ×1 |

---

## 12-7 道具與貨幣

| 道具/貨幣 | 說明 | 來源 |
|----------|------|------|
| 金幣 | 新貨幣，用於裝備購買/升級/修復/就醫 | 掛機（主）、未來金幣地下城 |
| 回憶碎片 | 解鎖回憶用，全新道具 | 鏟屎 |
| 鬍鬚 | 提升貓咪品階（現有道具） | 鏟屎、地下城、誘捕 |
| 貓糧 | 現有道具 | 掛機 |
| 鑽石 | 現有道具 | 掛機、課金 |

### 命名修正（待處理）
- 現有程式碼中「碎片」命名應統一改為「鬍鬚」（品階提升用道具）
- 「回憶碎片」為全新道具，命名上不與鬍鬚混用
