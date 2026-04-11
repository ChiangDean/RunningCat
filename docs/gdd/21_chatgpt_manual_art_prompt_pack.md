# 二十一、ChatGPT 手動出圖 Prompt 包與放置位置

最後更新：2026-04-11

## 1. 文件目的

本文件用於「不走 API、直接在 ChatGPT 介面手動出圖」的情境。

你可以直接把本文件中的 prompt 複製到 ChatGPT，生成後再把圖片存回本專案指定位置。

本文件重點回答兩件事：

- 要貼什麼 prompt
- 生成後圖片要放到哪裡

---

## 2. 目前建議的正式放置位置

依目前專案結構與既有用法，建議放置如下：

### A. 首頁 / 主視覺 / UI 頁面背景

放這裡：

- `assets/sprites/ui/`

建議檔名：

- `start_scene_homey_v2.png`
- `battle_background_homey_v1.png`
- `shop_background_homey_v1.png`
- `enhance_background_homey_v1.png`
- `gacha_background_homey_v1.png`

### B. 技能 Icon

放這裡：

- `assets/sprites/ui/skill_icons/`

建議檔名：

- `impact_v1.png`
- `shield_v1.png`
- `dash_v1.png`
- `buff_v1.png`
- `counter_v1.png`
- `strike_v1.png`
- `stagger_v1.png`
- `knockback_v1.png`

### C. 角色 Icon

放這裡：

- `assets/sprites/ui/cat_icons/`

建議檔名：

- `cat_icon_template_v1.png`

### D. 戰鬥姿勢基準圖

放這裡：

- `assets/generated/ai_seed/poses/`

建議檔名：

- `pose_idle_seed.png`
- `pose_run_seed.png`
- `pose_collide_seed.png`
- `pose_knockback_seed.png`
- `pose_stagger_seed.png`
- `pose_wall_bounce_seed.png`
- `pose_skill_seed.png`
- `pose_death_fly_seed.png`

說明：

- `poses` 這批先當設計基準，不建議直接當正式遊戲動畫素材
- 正式 sprite sheet 之後再另建資料夾比較合理

---

## 3. 生成後怎麼放

### 3.1 首頁背景

若你在 ChatGPT 生成了新的首頁圖，請放到：

- `C:\Users\Home\OneDrive\Desktop\MeowPartyDash\MeowPartyDashClient_art_assets\assets\sprites\ui\start_scene_homey_v2.png`

之後若要實際套用到遊戲，可把 [StartScene.gd](C:/Users/Home/OneDrive/Desktop/MeowPartyDash/MeowPartyDashClient_art_assets/scripts/StartScene.gd) 裡的：

```gdscript
const HERO_IMAGE := preload("res://assets/sprites/ui/start_scene_homey_v1.png")
```

改成：

```gdscript
const HERO_IMAGE := preload("res://assets/sprites/ui/start_scene_homey_v2.png")
```

### 3.2 戰鬥背景

若生成主戰鬥背景，先放到：

- `C:\Users\Home\OneDrive\Desktop\MeowPartyDash\MeowPartyDashClient_art_assets\assets\sprites\ui\battle_background_homey_v1.png`

說明：

- 目前戰鬥場景還是用程式畫底色，不是讀背景圖
- 所以這張先作為可整合素材
- 之後如果要接進 `BattleScene` 或 `ArenaBattleScene`，再由程式引用

### 3.3 技能 Icon

請放到：

- `C:\Users\Home\OneDrive\Desktop\MeowPartyDash\MeowPartyDashClient_art_assets\assets\sprites\ui\skill_icons\`

### 3.4 角色 Icon

請放到：

- `C:\Users\Home\OneDrive\Desktop\MeowPartyDash\MeowPartyDashClient_art_assets\assets\sprites\ui\cat_icons\`

### 3.5 姿勢基準圖

請放到：

- `C:\Users\Home\OneDrive\Desktop\MeowPartyDash\MeowPartyDashClient_art_assets\assets\generated\ai_seed\poses\`

---

## 4. 使用前建議先建立的資料夾

若資料夾還不存在，先建立：

```text
assets/sprites/ui/skill_icons/
assets/sprites/ui/cat_icons/
assets/generated/ai_seed/poses/
```

---

## 5. 可直接貼到 ChatGPT 的 Prompt

## 5.1 首頁主背景

生成後放到：

- `assets/sprites/ui/start_scene_homey_v2.png`

Prompt：

```text
請幫我生成一張直式手機遊戲首頁背景圖。

用途：首頁主背景
畫布尺寸：1440 x 2560
背景：不透明

場景：溫暖的公寓室內，從貓咪視角看到窗光、柔布窗簾、木地板、地毯、紙箱、貓碗、家具邊角，像家中的冒險舞台
主體：2 到 4 隻可愛的貓咪，以擬人化雙腳站立的小跑步姿勢一起往前衝，放在畫面下半部偏中間，帶有隊伍感與搶地盤的活力
構圖：上半部保留大量空間給標題，下半部保留按鈕空間，主體不要貼邊，整體維持手機首頁可疊 UI 的安全區
風格：溫暖居家的像素風遊戲主視覺，可愛但不幼稚，輪廓清楚，可讀性高，不要做成海報感
光線：午後窗光，舒服、親切、活潑、放鬆
色系：奶油牆、亞麻米色、暖木色、紙箱棕、灰綠布簾、自然毛色，低飽和暖色
材質：像素木紋、編織地毯、柔布窗簾、紙箱表面、柔和貓毛色塊

限制：不要文字、不要 logo、不要浮水印、不要 UI 外框
避免：霓虹、糖果色、科幻感、黑暗恐怖、現代 glossy app 風格、偶像海報感、過度 chibi
```

## 5.2 主戰鬥背景

生成後放到：

- `assets/sprites/ui/battle_background_homey_v1.png`

Prompt：

```text
請幫我生成一張直式手機遊戲戰鬥背景圖。

用途：主戰鬥背景
畫布尺寸：1440 x 2560
背景：不透明

場景：居家環境中的戰鬥場地，例如客廳、走廊或陽台，以木地板、地毯、窗簾、家具邊角、紙箱等元素組成
主體：以環境為主，可有極少量小型背景貓咪點綴，但不要影響中央戰鬥可讀性
構圖：中央碰撞區要乾淨，角色活動帶不要放高對比雜物，頂部 HUD 區、技能列區與底部導覽區都要可疊 UI
風格：可讀性高的像素風戰鬥背景，溫暖居家，不是奇幻戰場
光線：柔和日光或室內暖光
色系：自然居家色，木頭、布料、紙箱、牆面暖色
材質：像素木地板、地毯、布簾、家具邊角、家居道具

限制：不要文字、不要 logo、不要浮水印、不要 UI 外框
避免：畫面中央太花、海報式構圖、霓虹、科幻、恐怖、glossy app 風格
```

## 5.3 中性角色 Icon 樣板

生成後放到：

- `assets/sprites/ui/cat_icons/cat_icon_template_v1.png`

Prompt：

```text
請幫我生成一張手機遊戲角色 icon 樣板。

用途：角色 icon 構圖樣板
畫布尺寸：1024 x 1024
背景：透明背景

主體：一隻擬人化、雙腳站立的貓咪角色，上半身與頭部為主，輪廓清楚，不對應特定個體角色
構圖：主體置中，四周保留足夠留白，不要貼齊邊界，縮小成 128x128 後仍可辨識
風格：清楚可讀的像素風角色 icon，可愛但不過度 Q 版
色系：自然毛色，對比清楚但不要刺眼

限制：透明背景、不要文字、不要 logo、不要浮水印、不要外框
避免：海報式角度、太複雜配件、太細碎陰影
```

## 5.4 技能 Icon Prompt 模板

生成後放到：

- `assets/sprites/ui/skill_icons/<icon_name>.png`

Prompt 模板：

```text
請幫我生成一張手機遊戲技能 icon。

用途：技能列 icon
畫布尺寸：1024 x 1024
背景：透明背景

主體：一個清楚、集中的技能符號，主題是「<撞擊 / 護盾 / 衝刺 / Buff / 反擊 / 斬擊 / 暈眩 / 擊退>」
構圖：主圖形置中，四周留白，縮小成 128x128 後仍然一眼可讀
風格：乾淨、可讀性高的像素風 icon，不要做成整張小插畫
色系：限制色數，保留一個主要焦點色

限制：透明背景、不要文字、不要 logo、不要浮水印
避免：太細線條、太複雜場景、低對比、雜訊感
```

### 技能 icon 建議檔名對照

- 撞擊：`impact_v1.png`
- 護盾：`shield_v1.png`
- 衝刺：`dash_v1.png`
- Buff：`buff_v1.png`
- 反擊：`counter_v1.png`
- 斬擊：`strike_v1.png`
- 暈眩：`stagger_v1.png`
- 擊退：`knockback_v1.png`

## 5.5 戰鬥姿勢基準圖 Prompt 模板

生成後放到：

- `assets/generated/ai_seed/poses/pose_<action>_seed.png`

Prompt 模板：

```text
請幫我生成一張手機遊戲戰鬥角色姿勢基準圖。

用途：戰鬥動畫 key pose 參考圖，不是最終逐幀動畫
畫布尺寸：1024 x 1024
背景：透明背景

主體：一隻擬人化雙腳站立的貓咪，側面或 3/4 側面，全身完整可見，不對應特定個體角色
動作：<idle / run / collide / knockback / stagger / wall_bounce / skill / death_fly>
構圖：單一角色置中，全身完整，不貼邊，耳朵尾巴與肢體有足夠空間
風格：清楚可讀的像素風角色姿勢圖，可愛但不過度 chibi，適合家常貓咪戰鬥世界
動作要求：姿勢明確、輪廓清楚、縮小後仍看得懂重心與方向

限制：透明背景、不要文字、不要 logo、不要浮水印
避免：動作模糊、輪廓破碎、解剖不穩、過度細節
```

---

## 6. 你現在最該先生成哪幾張

如果你現在要先手動在 ChatGPT 出圖，我建議順序是：

1. `assets/sprites/ui/start_scene_homey_v2.png`
2. `assets/sprites/ui/battle_background_homey_v1.png`
3. `assets/sprites/ui/skill_icons/impact_v1.png`
4. `assets/sprites/ui/skill_icons/shield_v1.png`
5. `assets/sprites/ui/skill_icons/dash_v1.png`
6. `assets/generated/ai_seed/poses/pose_run_seed.png`
7. `assets/generated/ai_seed/poses/pose_collide_seed.png`

這樣你會最快看到：

- 首頁能不能換圖
- 戰鬥背景能不能成立
- icon 風格能不能讀
- 角色戰鬥姿勢方向有沒有走對

---

## 7. 使用原則

- 背景圖可以比較早直接測試整合
- icon 要先縮小檢查，不要只看大圖
- pose 圖先當動作方向稿，不要直接視為正式動畫成品
- 若結果不穩，優先重生，不要急著硬修第一版

本文件就是給你手動在 ChatGPT 出圖時直接使用的工作單。
