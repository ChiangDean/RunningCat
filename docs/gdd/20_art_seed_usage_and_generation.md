# 二十、第一批美術 Seed 使用與生成說明

最後更新：2026-04-11

## 1. 文件目的

本文件說明 `codex/art-assets-seed` worktree 內第一批 AI 美術 seed 的用途、輸出位置、整合方式與目前生成狀態。

這份文件主要回答兩件事：

- 這批圖是拿來做什麼的
- 生成後要怎麼用，不要誤把 seed 圖直接當最終成品

---

## 2. Worktree 與 Branch

- Worktree：`C:\Users\Home\OneDrive\Desktop\MeowPartyDash\MeowPartyDashClient_art_assets`
- Branch：`codex/art-assets-seed`

本批資產、批次 prompt 與說明文件皆放在這個 worktree 中，避免影響原本工作樹。

---

## 3. 相關檔案位置

### Prompt 與批次檔

- `tmp/imagegen/art_seed_jobs.jsonl`

### ChatGPT 手動出圖 Prompt 包

- `docs/gdd/21_chatgpt_manual_art_prompt_pack.md`

### 原始輸出目錄

- `assets/generated/ai_seed/raw/`

### 參考規格文件

- `docs/gdd/17_art_asset_production_spec.md`
- `docs/gdd/18_ai_art_prompt_pack.md`
- `docs/gdd/19_art_asset_checklist.md`

---

## 4. 本批預定產出項目

## 4.1 首頁主背景

- 目標檔名：`home_title_background_seed.png`
- 用途：首頁主畫面背景候選圖
- 怎麼使用：
  1. 先檢查上方標題區與下方按鈕區是否乾淨
  2. 若構圖可用，可直接作為首頁背景初稿
  3. 若主體位置略偏，可裁切或二次生成

## 4.2 主戰鬥背景

- 目標檔名：`battle_background_seed.png`
- 用途：主戰鬥與競技場共用背景候選圖
- 怎麼使用：
  1. 先檢查中央碰撞區是否夠乾淨
  2. 再檢查技能列與底部導覽區是否被重要物件壓到
  3. 若符合可讀性，可先用於一期整合

## 4.3 中性角色 Icon 樣板

- 目標檔名：`character_icon_neutral_seed.png`
- 用途：角色小圖示構圖樣板
- 怎麼使用：
  1. 不直接代表某一隻貓
  2. 用來檢查 `128x128` icon 的頭部、輪廓與裁切比例
  3. 之後製作正式角色 icon 時，沿用這個構圖邏輯

## 4.4 技能 Icon 樣板

- 目標檔名：
  - `skill_icon_impact_seed.png`
  - `skill_icon_shield_seed.png`
  - `skill_icon_dash_seed.png`
  - `skill_icon_buff_seed.png`
  - `skill_icon_counter_seed.png`
  - `skill_icon_strike_seed.png`
  - `skill_icon_stagger_seed.png`
  - `skill_icon_knockback_seed.png`
- 用途：技能 icon 視覺方向樣板
- 怎麼使用：
  1. 先縮到 `128x128`
  2. 檢查在技能列內是否仍一眼可讀
  3. 可作為後續正式技能 icon 的風格基準

## 4.5 戰鬥 Key Pose 樣板

- 目標檔名：
  - `pose_idle_seed.png`
  - `pose_run_seed.png`
  - `pose_collide_seed.png`
  - `pose_knockback_seed.png`
  - `pose_stagger_seed.png`
  - `pose_wall_bounce_seed.png`
  - `pose_skill_seed.png`
  - `pose_death_fly_seed.png`
- 用途：戰鬥動畫姿勢基準圖
- 怎麼使用：
  1. 這些不是完整逐幀動畫
  2. 主要用來確認站姿、跑步方向、碰撞姿勢、擊退與死亡姿勢
  3. 後續若做 sprite sheet，應以這些圖作為關鍵姿勢參考，而不是直接拆成動畫

---

## 5. 生成指令

```text
python C:\Users\Home\.codex\skills\.system\imagegen\scripts\image_gen.py generate-batch --input C:\Users\Home\OneDrive\Desktop\MeowPartyDash\MeowPartyDashClient_art_assets\tmp\imagegen\art_seed_jobs.jsonl --out-dir C:\Users\Home\OneDrive\Desktop\MeowPartyDash\MeowPartyDashClient_art_assets\assets\generated\ai_seed\raw --concurrency 2 --max-attempts 2
```

---

## 6. 目前實際狀態

本次已成功完成：

- 新 worktree 建立
- 新 branch 建立
- 第一批 seed prompt 批次檔建立
- ChatGPT 手動出圖 prompt 包建立
- 輸出目錄建立
- 規格與用途文件建立

本次未成功完成：

- 實際圖片生成

失敗原因：

- OpenAI Image API 回傳 `billing_hard_limit_reached`

這代表 prompt、路徑與工作樹都已備好，但帳號目前無法實際產圖。

---

## 7. 之後恢復生成時的操作順序

1. 確認可用的 API 額度
2. 重新執行批次生成指令
3. 檢查 `assets/generated/ai_seed/raw/` 的輸出
4. 對背景圖做 UI 安全區檢查
5. 對 icon 圖做縮小可讀性檢查
6. 對 pose 圖做姿勢一致性檢查
7. 挑出可用版本後，再移到正式資產目錄或再做二次修整

---

## 8. 使用原則

- 背景圖可以較早直接進遊戲測試
- icon 圖先當樣板，不急著當正式最終稿
- pose 圖只用來定義動作方向與風格，不當最終動畫交付
- 若 AI 第一次結果太不穩，優先重生，不要急著細修所有圖

本文件作為這一批 seed 圖的操作說明與交付備忘錄。

---

## 9. 從姿勢基準圖到正式動畫的流程

戰鬥姿勢基準圖不是最終動畫，而是正式動畫前的關鍵動作設計稿。

### 9.1 先確認姿勢方向

先用 key pose 圖確認以下事情：

- 站姿是否符合本遊戲的雙腳站立貓咪方向
- 跑步是否真的有往前衝的重心
- 碰撞是否有身體前頂的衝擊感
- 擊退、硬直、撞牆、技能、死亡彈飛是否彼此可明確區分
- 輪廓在縮小後是否仍看得懂

如果這一步不對，不要直接進逐幀動畫。

### 9.2 選定每個動作的一張主姿勢

每個動作先挑一張最接近需求的圖，當作該動作的主 key pose。

建議至少先挑這 8 類：

- `idle`
- `run`
- `collide`
- `knockback`
- `stagger`
- `wall_bounce`
- `skill`
- `death_fly`

這一步的目的不是追求完美，而是先定出每個動作的視覺語言。

### 9.3 補出前後過渡姿勢

有了主姿勢後，再補動作的前後過渡圖。

例如：

- `run`：接地、跨步、重心轉移
- `collide`：預備前傾、撞擊瞬間、撞後回彈
- `death_fly`：離地、空中翻轉、失衡下墜

這一步才開始接近動畫，而不是只看單張 pose。

### 9.4 統一角色比例與對齊點

在做正式動畫前，必須先統一：

- 頭身比例
- 耳朵與尾巴長度
- 腳底基準線
- 身體中心點
- 每張圖的站位基準

否則後面即使畫得漂亮，播起來也會晃。

### 9.5 轉成正式逐幀動畫

當姿勢、比例、對齊點都穩定後，再製作正式逐幀。

建議幀數：

- 待機：`4 ~ 6 幀`
- 跑步：`6 ~ 8 幀`
- 碰撞：`3 ~ 5 幀`
- 被擊退：`3 ~ 4 幀`
- 硬直：`2 ~ 3 幀`
- 撞牆：`3 ~ 4 幀`
- 技能：`4 ~ 8 幀`
- 死亡彈飛：`4 ~ 6 幀`

### 9.6 最後才切 sprite sheet

只有在逐幀穩定後，才建議輸出成正式 sprite sheet 或命名好的單幀序列。

不要反過來先切圖，再邊播邊修動作，這樣很容易亂掉。

---

## 10. 哪些可以直接用，哪些不能直接用

### 可以比較早直接用

- 首頁背景
- 戰鬥背景
- 技能 icon 樣板
- 角色 icon 構圖樣板

### 不建議直接當最終成品

- pose 基準圖

原因：

- pose 圖通常只有單張
- 沒有過渡幀
- 沒有統一對齊點驗證
- 沒有動畫播放測試

所以它們適合做方向確認，不適合直接當正式戰鬥動畫素材。
