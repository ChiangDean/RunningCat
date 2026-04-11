# 十八、AI 美術生成 Prompt 範本包

最後更新：2026-04-11

## 1. 文件目的

本文件提供《喵喵衝撞派對》常用圖片類型的 AI 生成 Prompt 範本。

使用方式：

1. 先讀 [13_image_art_direction.md](13_image_art_direction.md)
2. 再讀 [17_art_asset_production_spec.md](17_art_asset_production_spec.md)
3. 依圖片用途，從本文件挑選對應模板
4. 將尖括號欄位替換成這次需求

本文件以「可直接貼給 AI」為目標撰寫，重點是讓輸出更穩定、可裁切、可整合。

---

## 2. 共通輸入規則

每次要求 AI 製圖時，至少要補齊以下資訊：

```text
Asset type:
Use case:
Canvas size:
Background:
Subject count:
Subject framing:
Subject size ratio:
Safe area to preserve:
Style direction:
Environment:
Lighting:
Palette:
Constraints:
Avoid:
```

### 共通限制句

建議所有圖片都附上以下限制：

```text
no text, no logos, no watermark, no UI frame, no signature, clean readable composition, suitable for mobile game production
```

### 共通禁止方向

```text
avoid neon colors, candy palette, sci-fi look, horror mood, glossy modern app style, idol poster composition, over-chibi mascot style
```

---

## 3. 通用總模板

```text
Use case: stylized-concept
Asset type: <asset type>
Primary request: <one-sentence request>

Canvas size: <canvas size>
Background: <transparent or opaque>

Scene/backdrop: <environment description>
Subject: <subject description>
Subject count: <count>
Subject framing: <framing rule>
Subject size ratio: <ratio rule>
Safe area to preserve: <safe area rule>

Style/medium: charming pixel-art illustration, clean readable shapes, polished 2D game art, family-friendly, cute but not overly chibi, domestic cat-world feeling
Lighting/mood: <lighting and mood>
Color palette: warm natural home palette, low saturation, readable value contrast
Materials/textures: pixel-art wood, fabric, cardboard, rug, fur blocks, readable household props

Constraints: <production constraints>
Avoid: no text, no logos, no watermark, no UI frame, no signature, avoid neon colors, candy palette, sci-fi look, horror mood, glossy modern app style
```

---

## 4. 背景圖 Prompt

## 4.1 首頁主背景

```text
Use case: stylized-concept
Asset type: mobile game title background illustration
Primary request: a cozy domestic cat-world background for a vertical mobile game title screen, with a home interior seen from a cat-scale point of view

Canvas size: 1440 x 2560
Background: opaque

Scene/backdrop: warm apartment interior with window light, curtain, wood floor, rug, cardboard box, cat bowl, furniture corners, lived-in home details
Subject: 2 to 4 cute cats moving upright on two legs with team energy, playful territorial competition, lower-middle part of the image
Subject count: 2 to 4
Subject framing: keep upper area spacious for title overlay, keep lower area readable for start button overlay
Subject size ratio: cat group occupies around 25 to 35 percent of total image height
Safe area to preserve: top title area, center readability, lower button area, bottom navigation-safe zone

Style/medium: charming pixel-art illustration, clean readable shapes, polished 2D game key art, cozy domestic atmosphere, not anime poster style
Lighting/mood: warm afternoon window light, cheerful, relaxed, homey, playful
Color palette: cream wall, linen beige, honey wood floor, cardboard brown, muted natural fur colors, gray-green fabric
Materials/textures: pixel-art wood grain, woven rug texture, curtain fabric, cardboard surface, soft fur color blocks

Constraints: no text, no logos, no watermark, no UI frame, suitable for mobile vertical title background, preserve clean safe area for overlay
Avoid: neon colors, candy palette, sci-fi look, horror mood, glossy app style, heavy idol composition, over-chibi mascot style
```

## 4.2 戰鬥背景

```text
Use case: stylized-concept
Asset type: battle background illustration
Primary request: a vertical mobile battle background set in a domestic environment, readable behind moving cats and collision action

Canvas size: 1440 x 2560
Background: opaque

Scene/backdrop: living room, hallway, balcony, rooftop terrace, or cozy home-adjacent territory with warm natural materials
Subject: mostly environment, optional tiny background cats only if they do not reduce readability
Subject count: 0 to 3 small background subjects
Subject framing: keep the central collision lane clear, keep the battle character zone readable, avoid strong contrast directly behind characters
Subject size ratio: no single subject larger than 20 percent of image height
Safe area to preserve: top HUD area, center combat lane, skill bar zone, bottom navigation zone

Style/medium: readable pixel-art game background, warm domestic environment, clean shapes, low visual noise
Lighting/mood: soft daylight or warm interior light, energetic but comfortable
Color palette: natural home palette, wood, cloth, cardboard, soft wall colors
Materials/textures: readable wood floor, rug, curtain, furniture edges, cat-world home props

Constraints: no text, no logos, no watermark, no UI frame, keep the center readable for combat
Avoid: crowded center, dramatic poster composition, neon, sci-fi, horror, glossy app look
```

## 4.3 商店背景

```text
Use case: stylized-concept
Asset type: shop background illustration
Primary request: a cozy supply corner of a home seen as a cat-world shop scene, suitable for a mobile game shop page

Canvas size: 1440 x 2560
Background: opaque

Scene/backdrop: snack shelf, cardboard box stack, toy basket, canned food area, storage corner inside a warm apartment
Subject: environment-first composition, optional small cat presence only as supporting detail
Subject count: 0 to 2
Subject framing: preserve center and lower-middle readability for shop panels and buttons
Subject size ratio: supporting subjects only
Safe area to preserve: top header area, center panel area, lower button area, bottom navigation zone

Style/medium: cozy pixel-art environment, readable production background, domestic and playful
Lighting/mood: warm, inviting, comfortable, collectible-oriented
Color palette: warm wood, beige, cardboard brown, soft cloth colors, muted product accents
Materials/textures: boxes, woven baskets, wood shelf, cat supplies, simple readable props

Constraints: no text, no logos, no watermark, no UI frame, should support shop UI overlays
Avoid: treasure-room fantasy, sci-fi vending machine look, neon, glossy ad style
```

## 4.4 養成背景

```text
Use case: stylized-concept
Asset type: character growth page background
Primary request: a calm and cozy resting area for cats inside a home, suitable for a character growth or companion page

Canvas size: 1440 x 2560
Background: opaque

Scene/backdrop: window-side nest, cat room, memory shelf, scratching post corner, soft blanket area, comfortable domestic resting place
Subject: background-led, with optional small supporting cat silhouettes or decor only
Subject count: 0 to 2
Subject framing: leave center room for character card and stat panels
Subject size ratio: supporting subjects only
Safe area to preserve: top title area, center character panel area, lower action area, bottom nav area

Style/medium: warm domestic pixel-art interior, companion-focused, soft but readable
Lighting/mood: peaceful, intimate, warm daylight or soft indoor light
Color palette: cream, beige, warm wood, muted cloth greens and browns
Materials/textures: blanket, fabric, wood, shelf, cat furniture, memory display props

Constraints: no text, no logos, no watermark, no UI frame, must support overlay panels
Avoid: loud action scene, cluttered center, neon, fantasy shrine, glossy UI ad style
```

## 4.5 抽卡背景

```text
Use case: stylized-concept
Asset type: gacha background illustration
Primary request: a playful discovery scene in a domestic cat-world, like opening boxes and finding cat treasures inside a home

Canvas size: 1440 x 2560
Background: opaque

Scene/backdrop: cardboard boxes, cans, hidden supplies, surprise corner, warm home interior with a sense of reveal
Subject: environment with discovery energy, optional supporting cat action
Subject count: 0 to 2
Subject framing: keep center readable for reveal effect and reward overlays
Subject size ratio: medium supporting elements only
Safe area to preserve: top title area, center reveal zone, lower confirmation button area

Style/medium: polished pixel-art reveal scene, homey surprise feeling, cute but not childish
Lighting/mood: warm, exciting, playful, treasure-discovery feeling without fantasy summoning
Color palette: cardboard brown, warm beige, soft gold highlights, home interior colors
Materials/textures: box surfaces, soft cloth, floor, cat supply props

Constraints: no text, no logos, no watermark, no UI frame, keep reveal zone clean
Avoid: sci-fi portal, magic circle, fantasy summoning altar, neon, horror
```

---

## 5. 角色靜態圖 Prompt

## 5.1 小圖示 Icon

```text
Use case: production-asset
Asset type: character icon
Primary request: a readable upright anthropomorphic cat character icon for a mobile game team slot

Canvas size: 128 x 128
Background: transparent

Scene/backdrop: none
Subject: one upright cat character, head and upper body emphasis, readable silhouette
Subject count: 1
Subject framing: centered, not touching the edges
Subject size ratio: subject occupies around 70 percent of the canvas
Safe area to preserve: at least 16 pixels empty margin on all sides

Style/medium: pixel-art character icon, readable at small size, cute but not over-chibi
Lighting/mood: clean and neutral, easy to read in UI
Color palette: natural fur colors with controlled contrast
Materials/textures: minimal, shape-first

Constraints: transparent background, no text, no logos, no watermark, no frame, no tiny accessories that disappear at small size
Avoid: poster composition, dramatic perspective, noisy shading
```

## 5.2 半身角色圖

```text
Use case: production-asset
Asset type: character bust illustration
Primary request: a half-body upright cat character image for info panels and skill descriptions

Canvas size: 512 x 512
Background: transparent

Scene/backdrop: none
Subject: one upright cat character, bust or waist-up framing, expressive but controlled
Subject count: 1
Subject framing: centered or slightly off-center, preserve crop safety
Subject size ratio: subject occupies around 65 to 75 percent of the canvas
Safe area to preserve: keep at least 32 pixels clear around the outer edge

Style/medium: polished pixel-art character illustration, readable, game-ready
Lighting/mood: soft readable light
Color palette: natural cat fur colors, warm controlled tones
Materials/textures: shape clarity first, small texture only if readable

Constraints: transparent background, no text, no logos, no watermark, no frame
Avoid: full-body pose squeezed into the square, tiny props, noisy detail
```

## 5.3 全身展示圖

```text
Use case: production-asset
Asset type: full-body character display illustration
Primary request: a full-body upright cat character image for character detail pages and promotion panels

Canvas size: 768 x 1024
Background: transparent

Scene/backdrop: none
Subject: one full-body upright cat character with a clear pose and readable silhouette
Subject count: 1
Subject framing: full body fully visible, centered, feet not cropped
Subject size ratio: subject occupies around 70 percent of total image height
Safe area to preserve: at least 48 pixels top margin and 48 to 72 pixels bottom margin

Style/medium: clean polished pixel-art game illustration, readable silhouette, not poster-like
Lighting/mood: soft readable character presentation
Color palette: natural fur palette with selective accent color only if needed
Materials/textures: limited and readable, shape-first

Constraints: transparent background, no text, no logos, no watermark, no decorative frame
Avoid: exaggerated foreshortening, off-center crop risk, thin details that vanish when scaled down
```

## 5.4 技能 Icon

```text
Use case: production-asset
Asset type: skill icon
Primary request: a readable pixel-art skill icon for a mobile game combat skill bar

Canvas size: 128 x 128
Background: transparent

Scene/backdrop: none
Subject: one strong central action symbol representing impact, shield, dash, counter, buff, or strike
Subject count: 1
Subject framing: centered with clear negative space around the main symbol
Subject size ratio: main symbol occupies around 60 to 70 percent of the canvas
Safe area to preserve: keep important detail inside the central 96 x 96 area

Style/medium: clean pixel-art icon, readable at small size, game-ready
Lighting/mood: high readability, clear action emphasis
Color palette: limited palette with one focal accent color
Materials/textures: minimal, icon-like

Constraints: transparent background, no text, no logos, no watermark, no tiny decorative clutter
Avoid: full scene illustration, thin line complexity, muddy low-contrast colors
```

---

## 6. 角色動畫圖 Prompt

## 6.1 通用模板

```text
Use case: production-asset
Asset type: pixel-art animation frame sheet
Primary request: an upright anthropomorphic cat battle animation for a mobile game

Canvas size: 160 x 160 per frame
Background: transparent

Subject: one upright cat character, side view or 3/4 side view, readable silhouette, game-ready
Animation action: <idle / run / collide / knockback / stagger / wall_bounce / skill / death_fly>
Frame count target: <frame count>
Direction: facing right
Subject size ratio: standing body height around 96 to 128 pixels
Safe area to preserve: keep full body inside frame with enough motion margin for ears, tail, limbs

Style/medium: clean readable pixel-art animation, domestic cat battle style, not over-chibi
Motion tone: <motion description>
Color palette: natural cat fur colors, readable contrast

Constraints: transparent background, no text, no logos, no watermark, consistent body proportions across all frames
Avoid: smear that destroys silhouette, over-detailed shading, off-model anatomy
```

## 6.2 動作補充語句

可依動作替換 `Motion tone`：

- `idle`: gentle breathing loop, subtle body sway, light tail movement, calm but ready
- `run`: upright two-leg run, clear forward momentum, alternating leg stride, energetic team-run feeling
- `collide`: chest-forward impact motion, brief compressed anticipation then strong forward hit
- `knockback`: body pushed backward, feet losing balance, clear recoil direction
- `stagger`: brief dizzy instability, weight shifted off-center, interrupted movement
- `wall_bounce`: sharp recoil after hitting a wall, compressed contact pose then bounce-back
- `skill`: short emphasized action pose with readable power focus, suitable for auto-skill activation
- `death_fly`: body thrown into the air with loss of balance, readable airborne rotation or tumble

---

## 7. AI 輸出後檢查清單

AI 輸出後，至少檢查以下項目：

- 是否有文字、浮水印、Logo
- 是否保留指定透明背景
- 是否貼邊
- 是否壓到安全區
- 是否在縮小後仍看得懂
- 是否過度海報感
- 是否偏離居家世界觀
- 是否顏色過亮或過粉
- 是否能和其他素材放在同一頁面而不突兀

若有 2 項以上不符合，建議直接重生，不要硬修。

---

## 8. 本次 Seed 圖批次檔

本 worktree 已建立本次第一批 P0/樣板資產的批次 prompt 檔：

- `tmp/imagegen/art_seed_jobs.jsonl`

用途：

- 批次生成首頁主背景
- 批次生成主戰鬥背景
- 批次生成 1 張中性角色 icon 樣板
- 批次生成 8 張技能 icon 樣板
- 批次生成 8 張戰鬥 key pose 樣板

使用方式：

1. 確認 `OPENAI_API_KEY` 可正常使用且帳號額度可出圖
2. 於本 worktree 根目錄執行 CLI fallback
3. 將輸出存入 `assets/generated/ai_seed/raw/`

範例指令：

```text
python C:\Users\Home\.codex\skills\.system\imagegen\scripts\image_gen.py generate-batch --input C:\Users\Home\OneDrive\Desktop\MeowPartyDash\MeowPartyDashClient_art_assets\tmp\imagegen\art_seed_jobs.jsonl --out-dir C:\Users\Home\OneDrive\Desktop\MeowPartyDash\MeowPartyDashClient_art_assets\assets\generated\ai_seed\raw --concurrency 2 --max-attempts 2
```

注意：

- `raw` 內輸出的是原始 AI 生成圖
- 背景圖可直接挑選後整合
- icon 與 pose 圖屬於種子圖，建議後續縮放、裁切、像素修整後再正式導入
