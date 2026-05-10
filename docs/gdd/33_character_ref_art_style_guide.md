# 33 角色定稿圖風格與製作規範

## 目的

本文件定義 `assets/sprites/cdn/ui/character_refs/` 角色定稿圖的固定製作方式，目標是讓不同角色都能維持和現有 `MeowPartyDashClient` 一致的視覺語言。

本文件適用於：

- `*_icon_v1.png`
- `*_ref_front_v1.png`
- `*_ref_right_v1.png`
- `*_ref_three_quarter_v1.png`
- `*_pose_skill_v1.png`

不適用於：

- `assets/sprites/battle/cats/**` 戰鬥 sprite sheet
- 背景圖
- UI 卡面 / reward icon

若新需求沒有明確推翻本文件，角色定稿圖一律以本文件為準。

## 必須使用的 Skill

### 1. 角色定稿圖

角色定稿圖預設使用：

- `imagegen`
- 路徑：`C:\Users\Home\.codex\skills\.system\imagegen\SKILL.md`

原因：

- 角色定稿圖是單張插圖資產，不是 sprite sheet。
- 需要先把角色造型、比例、陰影、服裝辨識度定下來。
- `imagegen` 比較適合產出 `icon / front / right / three_quarter / pose_skill` 這種單張定稿圖。

### 2. 戰鬥 sprite / 動畫 sheet

戰鬥 sprite 預設使用：

- `generate2dsprite`
- 路徑：`C:\Users\Home\.codex\skills\generate2dsprite\SKILL.md`

原因：

- `generate2dsprite` 適合處理固定格數、固定 frame、固定背景鍵色的 sprite sheet。
- 它的重點是動畫格切分、對齊、去背、輸出透明 sheet，不是角色定稿圖本身。

### 3. Skill 選用規則

簡單規則如下：

- 要做角色定稿圖：先用 `imagegen`
- 要做戰鬥動畫 sheet：用 `generate2dsprite`
- 不要直接拿 `generate2dsprite` 取代角色定稿圖流程
- 不要先做寫實立繪再硬改成 sprite，這樣風格通常會跑掉

## 風格來源

角色定稿圖必須同時參考以下來源：

1. `docs/gdd/13_image_art_direction.md`
2. `docs/gdd/09_onboarding_art_requests.md`
3. 現有 `assets/sprites/cdn/ui/character_refs/` 已落地角色

目前優先參考的同風格資產：

- `tuxedo_cat`
- `orange_cat`
- `ninja_cat`
- `milk_cat`
- `calico_cat`
- `silver_cat`

## 核心視覺規則

### 1. 比例

角色必須維持：

- Q 版
- 頭大身小
- 雙腳站立
- 約 `2.3 ~ 2.5` 頭身
- 手腳短但要有戰鬥角色的站姿張力

禁止：

- 修長比例
- 接近 3 頭身以上的人形比例
- 四腳真貓比例
- 上半身過長或腿過長

### 2. 陰影

角色陰影必須維持：

- `simple flat colour illustration with soft shading`
- 兩到三階明暗即可
- 陰影服務於造型辨識，不是服務於寫實光感
- 可以有少量柔和過渡，但不能做厚塗體積感

禁止：

- 寫實毛流
- 臉部大面積空氣透視
- 電影感高反差打光
- 金屬般高光
- 過深、過硬、過立體的寫實陰影

### 3. 線條與邊界

角色輪廓要清楚：

- 外輪廓要乾淨
- 服裝分塊要大，不要碎
- 臉部五官要一眼可讀
- 黑色或深色角色必須靠輪廓和局部亮面保持可讀性

### 4. 材質

角色材質方向：

- 偏遊戲插圖
- 偏平塗 + 柔和陰影
- 可有少量布料折線
- 可有簡單皮帶、布巾、護腕層次

禁止：

- 皮毛根根分明
- 寫實布料紋理
- 過度複雜金屬裝甲
- 太多小配件導致縮小後看不懂

## 臉部規則

角色頭像與定稿圖的臉必須遵守：

- 眼睛大而可讀
- 鼻子小
- 嘴巴簡潔
- 表情可愛，但要保留角色職業個性
- 臉頰與下巴要用簡單幾何塊面呈現

禁止：

- 真實貓科骨相
- 太尖太兇的寫實臉
- 太多毛束切面
- 過度成熟或過度擬真

## 服裝規則

服裝必須遵守：

- 一眼看得出職業
- 但仍屬於可愛手機遊戲角色
- 大塊色面優先
- 配件數量要克制

建議做法：

- 主體 2 到 3 個大色塊
- 1 到 2 個職業辨識配件
- 1 個局部重點色

例如 assassin 類型可用：

- 圍巾 / cowl
- 腰帶
- 匕首
- 護腕

但不要同時堆太多：

- 兜帽
- 披風
- 大片鎧甲
- 多把武器
- 大量飾品

## 構圖規則

### 1. Icon

- 只畫頭部到上胸
- 表情要清楚
- 縮小後仍能辨識
- 不要塞全身資訊

### 2. Front

- 正面站姿
- 全身完整入鏡
- 左右重心穩定
- 用來確認服裝正面配置

### 3. Right

- 右向側身或偏右 3/4
- 主要用來確認輪廓、尾巴、武器位置

### 4. Three Quarter

- 預設主定稿圖
- 最能代表角色完整辨識度
- 後續其他角度與頭像要向這張靠攏

### 5. Pose Skill

- 動態姿勢可以比一般定稿更誇張
- 但角色本體仍必須清楚
- 技能特效只能輔助，不可吃掉角色

## 輸出規格

目前 `character_refs` 建議統一如下：

- `*_icon_v1.png`：`256x256`
- `*_ref_front_v1.png`：`256x256`
- `*_ref_right_v1.png`：`256x256`
- `*_ref_three_quarter_v1.png`：`256x256`
- `*_pose_skill_v1.png`：`256x256`

背景規則：

- 交付進專案的最終檔一律透明背景

生成流程規則：

- 生成時先用純色背景方便去背
- 建議使用固定單色鍵色
- 去背後再置中到正式畫布

## 黑貓這次定稿的具體做法

`black_cat` 本次定稿採用以下方向：

- 以 `black_cat_ref_three_quarter_v1.png` 作為主身份基準
- 視覺語言參考 `ninja_cat` 的 assassin 類別可讀性
- 保留黑貓自己的元素：
  - 黑色毛皮
  - 金黃眼睛
  - 紫色圍巾
  - 短匕首
  - 輕量刺客裝
- 刻意壓低寫實陰影與毛流

這個方向之後如果要補 battle sprite，應以這套定稿為造型來源，不要重新發明角色。

## 推薦工作流程

1. 先決定角色職業與關鍵辨識元素
2. 先做 `ref_three_quarter`
3. 確認比例、臉、陰影都對
4. 再延伸做 `front / right / icon / pose_skill`
5. 全套完成後，再進入 battle sprite 流程
6. battle sprite 流程改用 `generate2dsprite`

## Prompt 原則

角色定稿圖 prompt 必須固定包含以下概念：

- cute chibi cartoon cat
- simple flat-colour illustration
- soft shading
- mobile idle game character art style
- no realistic fur rendering
- no cinematic lighting
- large head, short legs, compact torso
- clean readable silhouette

若角色是深色毛皮，額外要加：

- keep the character readable with simple silhouette separation
- subtle highlight accents only where needed for readability

## 禁止方向

以下結果視為不合格，應直接重做：

- 陰影太寫實
- 毛流太寫實
- 頭身比例拉長
- 角色像插畫立繪，不像遊戲角色定稿
- 配件細節過多，縮小後糊成一團
- 技能特效比角色還搶眼
- 每個角度長得像不同角色

## 驗收清單

交圖前至少確認：

- 是否一眼看得出是同一隻貓
- 是否符合 `2.3 ~ 2.5` 頭身
- 是否沒有寫實陰影
- 是否縮到 `256x256` 仍清楚
- 是否和 `character_refs` 其他角色放在一起不突兀
- 是否符合角色職業辨識
- 是否保留足夠透明邊界

