# 34 戰鬥 Sprite 製作規範

## 目的

本文件定義 `assets/sprites/battle/cats/` 的戰鬥動畫 strip 製作規則。

這份文件的重點不是角色定稿圖，而是：

- 戰鬥比例
- raw strip 構圖方式
- 最終 runtime frame 尺寸
- 何時用 `128x128`
- 何時升到 `160x128`

若新需求沒有明確推翻本文件，戰鬥 strip 一律以本文件為準。

## 必須使用的 Skill

戰鬥 strip 預設使用：

- `meow-party-dash-battle-sprites`
- 路徑：`C:\Users\Home\.codex\skills\meow-party-dash-battle-sprites\SKILL.md`

這個 skill 會處理：

- 參考定稿圖建立角色 identity
- raw strip prompt
- `generate2dsprite` 後處理
- 最終 strip 重包
- `128x128` / `160x128` 判斷

角色定稿圖請不要用本文件處理，改用：

- `meow-party-dash-character-refs`

## 風格來源

戰鬥 strip 必須同時參考：

1. `docs/gdd/03_battle.md`
2. `docs/gdd/13_image_art_direction.md`
3. `docs/gdd/17_art_asset_production_spec.md`
4. `docs/gdd/33_character_ref_art_style_guide.md`
5. 角色自己的 `character_refs`

優先參考的 battle 角色：

- `calico_cat`
- `milk_cat`
- `ninja_cat`
- `orange_cat`

## 戰鬥比例規則

戰鬥 strip 的比例可以和定稿圖略有不同。

目標讀感：

- 頭比定稿圖再大一點
- 身體比定稿圖再短一點
- 四肢更簡潔
- 戰鬥中一眼能看懂動作

若使用者指定像 `calico_cat` 這樣的比例，優先遵守 battle 讀感，而不是死守定稿圖比例。

## Raw Strip 最重要規則

### 核心原則

戰鬥 strip 是否成功，關鍵在 raw 階段，不在後處理。

raw 一開始就必須：

- 每格左右留寬
- 每格上下留安全距離
- 角色本體放在 cell 中央區域
- 不讓尾巴、圍巾、武器、特效貼邊

### 禁止錯誤做法

以下做法視為錯：

- 先把角色塞滿每格
- 之後再想靠切圖或縮放救回來
- 把特效故意做很大，指望 pack 時能收得回去

如果 raw strip 已經貼邊，正確做法是：

- 直接重生 raw

不是：

- 繼續硬修 final strip

## 最終輸出尺寸規則

### 預設首選

戰鬥 strip 最終優先使用：

- `128x128`

這是預設標準，不要一開始就跳過它。

### 升級條件

只有在下列情況成立時，才可以升到：

- `160x128`

成立條件：

- `128x128` 會讓角色明顯縮太小
- `128x128` 會讓關鍵動作讀不清
- `128x128` 會讓必要動作弧線被迫壓扁
- raw 留寬後，角色仍無法在 `128x128` 保持可讀

### 不可作為升級理由

以下理由不能直接拿來升級到 `160x128`：

- raw 畫太滿
- 特效做太長
- 沒有先做留寬版本

## 顯示尺寸與碰撞的關係

### 重要觀念

`frame size` 不等於碰撞箱。

透明外框變大，不代表碰撞就變大。

目前 client 縮放主要看的是：

- 可見像素區域
- 顯示 target size

而碰撞依據是：

- 戰鬥規則中的視覺接觸基準

所以：

- raw 留寬是安全的
- 最終 frame 用 `160x128` 也是安全的

真正要小心的是：

- 角色本體可見寬度如果被放得太大
- 視覺上會比碰撞判定更早接觸

因此正確策略是：

1. raw 先留寬
2. final 再 pack
3. 優先 `128x128`
4. 必要時單角色或單動作升 `160x128`
5. 不隨便讓角色本體變得過寬

## 動作規則

目前建議 frame 數：

- `idle`: 6
- `run`: 8
- `collide`: 4
- `knockback`: 6
- `stagger`: 4
- `skill`: 6
- `death_fly`: 6

高風險動作：

- `run`
- `skill`
- `knockback`
- `death_fly`

這四種在 raw prompt 中必須明寫：

- large empty left and right safety margins
- keep the character in the central area only
- no body part, scarf, tail, weapon, or effect may touch a cell border

## 特效規則

技能特效不是不能做大，但必須遵守：

- 特效必須貼近角色
- 特效不可變成 detached giant arc
- 特效不可逼近相鄰 cell 邊界

若特效常常導致 edge-touch：

- 優先縮短特效
- 優先讓特效貼近武器
- 不要第一時間升 final frame size

## 推薦流程

1. 先用 `character_refs` 定身份
2. 決定 battle 比例
3. 生 raw strip，先把 gutter 做對
4. 跑 `generate2dsprite` 抽 frame
5. 優先重包成 `128x128`
6. 若可讀性不足，再升 `160x128`
7. 若升級後 runtime 需要特殊顯示 target size，再加角色級 override

## 驗收清單

交付前至少確認：

- raw strip 沒有貼邊
- final strip 每格乾淨
- 沒有跨格殘片
- 角色動作縮小後仍清楚
- battle 比例比定稿更適合戰鬥閱讀
- `128x128` 真的不夠時才使用 `160x128`

