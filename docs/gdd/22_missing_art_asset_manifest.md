# 22 缺漏美術資產清單

## 目的

本文件整理目前 `MeowPartyDashClient` 缺少、但已經被前端流程、後端 API、或 DB catalog 定義所需求的圖片與動畫圖。

本文件的來源包含：

- Client 前端場景與 UI 腳本
- API controller / application model
- API dev seed 與 catalog schema

本次盤點結論：

- 黑貓素材已經開始補齊，故本文件不重複列黑貓。
- 其餘 5 隻正式貓咪角色，仍缺完整角色定稿、頭像、戰鬥動畫。
- client runtime 已補戰鬥動畫 fallback；當 `collide / knockback / stagger / skill / death_fly` 缺圖時，會先回退到現有 `run / idle` 類動畫，避免正式流程出現空動畫。
- 多數功能頁仍為純色背景，缺 UI 背景圖。
- API / DB 已經定義 `image_path` 的 catalog 圖資，目前前端多數尚未補圖或尚未實際套用。
- Mail / Chat / Shop / Scooper / Arena Reward / Dungeon Overview 等流程仍偏文字化，缺少對應 icon 或卡面圖。
- 前端 runtime 已補上 catalog 圖示、商店/背包圖示、功能頁預覽圖、背景圖的 fallback；缺圖時不再直接留白，但正式美術補齊需求仍然存在。

## 盤點依據

### Client 實作現況

- 已有：
  - `assets/sprites/ui/start_scene_homey_v1.png`
  - `assets/sprites/ui/battle_background_homey_v1.png`
  - `assets/sprites/ui/skill_icons/*.png`
  - `assets/sprites/ui/character_refs/black_cat/*`
  - `assets/sprites/battle/cats/black_cat/*`
- 仍為純色背景或文字 UI 的主要頁面：
  - `scripts/ActivityScene.gd`
  - `scripts/configs/ConfigScene.gd`
  - `scripts/enhance/EnhanceSceneUI.gd`
  - `scripts/dungeon/DungeonSceneUI.gd`
  - `scripts/arenaScene/ArenaScene.gd`
  - `scripts/scooper/ScooperScene.gd`
  - `scripts/shop/ShopScene.gd`
  - `scripts/gacha/GachaScene.gd`
  - `scripts/MailScene.gd`
  - `scripts/chat/ChatScene.gd`
- 戰鬥角色目前仍以 placeholder 為主：
  - `scripts/cats/cat_node.gd`

### API / DB 實際已有圖資欄位

- `currency_catalog.image_path`
- `consumable_catalog.image_path`
- `cat_catalog.image_path`
- `memory_catalog.image_path`
- `treasure_catalog.image_path`
- `dungeon_catalog.image_path`
- `arena_rank_catalog.image_path`
- `MailAttachmentResponse.ImagePath`
- `RewardPreviewResponse.ImagePath`

### DB 目前 seed 的 catalog 內容

- 貓咪：`black_cat` `calico_cat` `cow_cat` `milk_cat` `ninja_cat` `orange_cat` `tuxedo_cat`
- 額外預設敵人：`silver_cat`
- 地城：`cat_food` `diamond` `whisker`
- 牌位：`bronze_3` 到 `elite`
- 回憶：5 張
- 寶物：6 個
- 貨幣 / 消耗品：9 種常用 icon 類型

## 優先順序

### P0 立刻要補

- 其餘新版貓角色完整圖包
- 各主功能頁背景
- 地城縮圖
- 牌位徽章
- 回憶圖
- 寶物圖
- 貨幣 / 消耗品 icon

### P1 下一批建議補

- Shop 禮包卡面圖
- Gacha 結果 rarity 卡框
- Scooper 裝備 icon
- Scooper 特殊能力 icon
- Mail / Reward 通用卡片底圖

## A. 正式角色圖包

### 共用規則

- 角色風格固定為：像素風、可愛擬人化貓咪、雙腳站立、Q 版比例、頭大身小、適合手機遊戲戰鬥 sprite。
- 角色圖請維持同一角色辨識度，不可每張換長相。
- 背景要求：
  - 定稿 / icon / pose / sprite sheet 一律透明背景。
- Sprite sheet 規格：
  - 橫向 6 格
  - 每格 `160x160`
  - 總尺寸 `960x160`
  - 角色朝右

### `calico_cat`

角色固定描述：

`一隻可愛的三花擬人化貓咪，雙腳站立，橘黑白拼色毛皮，頭大身小，表情活潑開朗，動作很有彈性，像擅長衝刺突進的快節奏角色。`

1. 存放位置：`assets/sprites/ui/character_refs/calico_cat/`
   檔名：`calico_cat_ref_front_v1.png`
   Prompt：
   ```text
   請生成 1024x1024、透明背景的像素風角色定稿圖。
   角色是一隻可愛的三花擬人化貓咪，雙腳站立，橘黑白拼色毛皮，頭大身小，表情活潑開朗，動作很有彈性，像擅長衝刺突進的快節奏角色。
   視角為正面站立，全身完整入鏡，四周保留安全留白。
   風格必須是像素風、可愛擬人化、雙腳站立、Q版戰鬥角色，不要四腳真貓，不要厚塗，不要寫實。
   ```

2. 存放位置：`assets/sprites/ui/character_refs/calico_cat/`
   檔名：`calico_cat_ref_right_v1.png`
   Prompt：
   ```text
   請生成 1024x1024、透明背景的像素風角色定稿圖。
   角色是一隻可愛的三花擬人化貓咪，雙腳站立，橘黑白拼色毛皮，頭大身小，表情活潑開朗，動作很有彈性，像擅長衝刺突進的快節奏角色。
   視角為右側站立，全身完整入鏡，四周保留安全留白。
   風格必須是像素風、可愛擬人化、雙腳站立、Q版戰鬥角色，不要四腳真貓，不要厚塗，不要寫實。
   ```

3. 存放位置：`assets/sprites/ui/character_refs/calico_cat/`
   檔名：`calico_cat_ref_three_quarter_v1.png`
   Prompt：
   ```text
   請生成 1024x1024、透明背景的像素風角色定稿圖。
   角色是一隻可愛的三花擬人化貓咪，雙腳站立，橘黑白拼色毛皮，頭大身小，表情活潑開朗，動作很有彈性，像擅長衝刺突進的快節奏角色。
   視角為 3/4 側站立，全身完整入鏡，四周保留安全留白。
   風格必須是像素風、可愛擬人化、雙腳站立、Q版戰鬥角色，不要四腳真貓，不要厚塗，不要寫實。
   ```

4. 存放位置：`assets/sprites/ui/character_refs/calico_cat/`
   檔名：`calico_cat_icon_v1.png`
   Prompt：
   ```text
   請生成 256x256、透明背景的手機遊戲角色頭像。
   角色是一隻可愛的三花擬人化貓咪，雙腳站立角色語言，橘黑白拼色毛皮，頭大身小，表情活潑開朗，像快節奏突進型角色。
   構圖為頭像或半身像置中，縮小後仍要清楚辨識。
   風格必須是像素風、可愛擬人化、Q版，不要寫實，不要插畫海報風。
   ```

5. 存放位置：`assets/sprites/ui/character_refs/calico_cat/`
   檔名：`calico_cat_pose_idle_v1.png`
   Prompt：
   ```text
   請生成 1024x1024、透明背景的像素風戰鬥角色動作定稿圖。
   角色是一隻可愛的三花擬人化貓咪，雙腳站立，橘黑白拼色毛皮，頭大身小，表情活潑開朗。
   動作為待機：雙腳站立、微呼吸起伏、尾巴輕擺、可愛但準備戰鬥。
   必須維持同一隻角色，不可改變角色身份。
   ```

6. 存放位置：`assets/sprites/ui/character_refs/calico_cat/`
   檔名：`calico_cat_pose_run_v1.png`
   Prompt：
   ```text
   請生成 1024x1024、透明背景的像素風戰鬥角色動作定稿圖。
   角色是一隻可愛的三花擬人化貓咪，雙腳站立，橘黑白拼色毛皮，頭大身小，表情活潑開朗。
   動作為跑步：雙腳高速交替、身體前傾、節奏輕快、很有彈性。
   必須維持同一隻角色，不可改變角色身份。
   ```

7. 存放位置：`assets/sprites/ui/character_refs/calico_cat/`
   檔名：`calico_cat_pose_stagger_v1.png`
   Prompt：
   ```text
   請生成 1024x1024、透明背景的像素風戰鬥角色動作定稿圖。
   角色是一隻可愛的三花擬人化貓咪，雙腳站立，橘黑白拼色毛皮，頭大身小，表情活潑開朗。
   動作為受創踉蹌：身體歪斜、步伐亂掉、看起來被打到但仍可愛。
   必須維持同一隻角色，不可改變角色身份。
   ```

8. 存放位置：`assets/sprites/ui/character_refs/calico_cat/`
   檔名：`calico_cat_pose_skill_v1.png`
   Prompt：
   ```text
   請生成 1024x1024、透明背景的像素風戰鬥角色動作定稿圖。
   角色是一隻可愛的三花擬人化貓咪，雙腳站立，橘黑白拼色毛皮，頭大身小，表情活潑開朗。
   動作為技能施放：有明顯衝刺突進或加速爆發姿勢，輪廓清楚。
   必須維持同一隻角色，不可改變角色身份。
   ```

9. 存放位置：`assets/sprites/ui/character_refs/calico_cat/`
   檔名：`calico_cat_pose_death_fly_v1.png`
   Prompt：
   ```text
   請生成 1024x1024、透明背景的像素風戰鬥角色動作定稿圖。
   角色是一隻可愛的三花擬人化貓咪，雙腳站立，橘黑白拼色毛皮，頭大身小，表情活潑開朗。
   動作為死亡擊飛：被打飛、翻滾或騰空，誇張但不血腥，保持可愛。
   必須維持同一隻角色，不可改變角色身份。
   ```

10. 存放位置：`assets/sprites/battle/cats/calico_cat/`
    檔名：`calico_cat_idle_right.png`
    Prompt：`請生成透明背景橫向 sprite sheet，6 格動畫，每格 160x160，總尺寸 960x160；角色朝右；角色是一隻可愛的三花擬人化貓咪，雙腳站立，橘黑白拼色毛皮，頭大身小，表情活潑開朗；動作是待機；6 格維持同一隻角色；風格必須是像素風、Q版、適合手機遊戲戰鬥動畫。`

11. 存放位置：`assets/sprites/battle/cats/calico_cat/`
    檔名：`calico_cat_run_right.png`
    Prompt：`請生成透明背景橫向 sprite sheet，6 格動畫，每格 160x160，總尺寸 960x160；角色朝右；角色是一隻可愛的三花擬人化貓咪，雙腳站立，橘黑白拼色毛皮，頭大身小，表情活潑開朗；動作是跑步，要求步伐快速、有彈性、像衝刺型角色；6 格維持同一隻角色；風格必須是像素風、Q版、適合手機遊戲戰鬥動畫。`

12. 存放位置：`assets/sprites/battle/cats/calico_cat/`
    檔名：`calico_cat_collide_right.png`
    Prompt：`請生成透明背景橫向 sprite sheet，6 格動畫，每格 160x160，總尺寸 960x160；角色朝右；角色是一隻可愛的三花擬人化貓咪，雙腳站立，橘黑白拼色毛皮，頭大身小，表情活潑開朗；動作是撞擊，要求前衝感強、節奏短促、可看出蓄力與撞上瞬間；6 格維持同一隻角色；風格必須是像素風、Q版、適合手機遊戲戰鬥動畫。`

13. 存放位置：`assets/sprites/battle/cats/calico_cat/`
    檔名：`calico_cat_knockback_right.png`
    Prompt：`請生成透明背景橫向 sprite sheet，6 格動畫，每格 160x160，總尺寸 960x160；角色朝右；角色是一隻可愛的三花擬人化貓咪，雙腳站立，橘黑白拼色毛皮，頭大身小，表情活潑開朗；動作是擊退，要求被撞開、向後飛退、逐漸失衡；6 格維持同一隻角色；風格必須是像素風、Q版、適合手機遊戲戰鬥動畫。`

14. 存放位置：`assets/sprites/battle/cats/calico_cat/`
    檔名：`calico_cat_stagger_right.png`
    Prompt：`請生成透明背景橫向 sprite sheet，6 格動畫，每格 160x160，總尺寸 960x160；角色朝右；角色是一隻可愛的三花擬人化貓咪，雙腳站立，橘黑白拼色毛皮，頭大身小，表情活潑開朗；動作是受創踉蹌，要求身體歪斜、腳步不穩、表情可愛但受擊清楚；6 格維持同一隻角色；風格必須是像素風、Q版、適合手機遊戲戰鬥動畫。`

15. 存放位置：`assets/sprites/battle/cats/calico_cat/`
    檔名：`calico_cat_skill_right.png`
    Prompt：`請生成透明背景橫向 sprite sheet，6 格動畫，每格 160x160，總尺寸 960x160；角色朝右；角色是一隻可愛的三花擬人化貓咪，雙腳站立，橘黑白拼色毛皮，頭大身小，表情活潑開朗；動作是技能施放，要求像高速衝刺或瞬間突進，姿勢戲劇化但仍清楚可讀；6 格維持同一隻角色；風格必須是像素風、Q版、適合手機遊戲戰鬥動畫。`

16. 存放位置：`assets/sprites/battle/cats/calico_cat/`
    檔名：`calico_cat_death_fly_right.png`
    Prompt：`請生成透明背景橫向 sprite sheet，6 格動畫，每格 160x160，總尺寸 960x160；角色朝右；角色是一隻可愛的三花擬人化貓咪，雙腳站立，橘黑白拼色毛皮，頭大身小，表情活潑開朗；動作是死亡擊飛，要求被打飛後翻滾或騰空，誇張但不血腥；6 格維持同一隻角色；風格必須是像素風、Q版、適合手機遊戲戰鬥動畫。`

### `milk_cat`

角色固定描述：

`一隻可愛的牛奶色擬人化貓咪，雙腳站立，白色帶奶油色毛皮，身形稍微圓潤，神情溫和但可靠，像偏防禦保護型角色。`

1. 存放位置：`assets/sprites/ui/character_refs/milk_cat/`
   檔名：`milk_cat_ref_front_v1.png`
   Prompt：`請生成 1024x1024、透明背景的像素風角色定稿圖；角色是一隻可愛的牛奶色擬人化貓咪，雙腳站立，白色帶奶油色毛皮，身形稍微圓潤，神情溫和但可靠，像偏防禦保護型角色；視角為正面站立；全身完整入鏡；風格必須是像素風、可愛擬人化、雙腳站立、Q版戰鬥角色。`

2. 存放位置：`assets/sprites/ui/character_refs/milk_cat/`
   檔名：`milk_cat_ref_right_v1.png`
   Prompt：`請生成 1024x1024、透明背景的像素風角色定稿圖；角色是一隻可愛的牛奶色擬人化貓咪，雙腳站立，白色帶奶油色毛皮，身形稍微圓潤，神情溫和但可靠，像偏防禦保護型角色；視角為右側站立；全身完整入鏡；風格必須是像素風、可愛擬人化、雙腳站立、Q版戰鬥角色。`

3. 存放位置：`assets/sprites/ui/character_refs/milk_cat/`
   檔名：`milk_cat_ref_three_quarter_v1.png`
   Prompt：`請生成 1024x1024、透明背景的像素風角色定稿圖；角色是一隻可愛的牛奶色擬人化貓咪，雙腳站立，白色帶奶油色毛皮，身形稍微圓潤，神情溫和但可靠，像偏防禦保護型角色；視角為 3/4 側站立；全身完整入鏡；風格必須是像素風、可愛擬人化、雙腳站立、Q版戰鬥角色。`

4. 存放位置：`assets/sprites/ui/character_refs/milk_cat/`
   檔名：`milk_cat_icon_v1.png`
   Prompt：`請生成 256x256、透明背景的手機遊戲角色頭像；角色是一隻可愛的牛奶色擬人化貓咪，雙腳站立角色語言，白色帶奶油色毛皮，身形稍微圓潤，神情溫和但可靠，像偏防禦保護型角色；構圖為頭像或半身像置中；風格必須是像素風、可愛擬人化、Q版。`

5. 存放位置：`assets/sprites/ui/character_refs/milk_cat/`
   檔名：`milk_cat_pose_idle_v1.png`
   Prompt：`請生成 1024x1024、透明背景的像素風戰鬥角色動作定稿圖；角色是一隻可愛的牛奶色擬人化貓咪，雙腳站立，白色帶奶油色毛皮，身形稍微圓潤，神情溫和但可靠；動作為待機，要求站姿穩定、有守護感；必須維持同一隻角色。`

6. 存放位置：`assets/sprites/ui/character_refs/milk_cat/`
   檔名：`milk_cat_pose_run_v1.png`
   Prompt：`請生成 1024x1024、透明背景的像素風戰鬥角色動作定稿圖；角色是一隻可愛的牛奶色擬人化貓咪，雙腳站立，白色帶奶油色毛皮，身形稍微圓潤，神情溫和但可靠；動作為跑步，要求步伐穩重但不笨重；必須維持同一隻角色。`

7. 存放位置：`assets/sprites/ui/character_refs/milk_cat/`
   檔名：`milk_cat_pose_stagger_v1.png`
   Prompt：`請生成 1024x1024、透明背景的像素風戰鬥角色動作定稿圖；角色是一隻可愛的牛奶色擬人化貓咪，雙腳站立，白色帶奶油色毛皮，身形稍微圓潤，神情溫和但可靠；動作為受創踉蹌，要求被撞到後仍努力站穩；必須維持同一隻角色。`

8. 存放位置：`assets/sprites/ui/character_refs/milk_cat/`
   檔名：`milk_cat_pose_skill_v1.png`
   Prompt：`請生成 1024x1024、透明背景的像素風戰鬥角色動作定稿圖；角色是一隻可愛的牛奶色擬人化貓咪，雙腳站立，白色帶奶油色毛皮，身形稍微圓潤，神情溫和但可靠；動作為技能施放，要求像舉起防護或撐起護盾；必須維持同一隻角色。`

9. 存放位置：`assets/sprites/ui/character_refs/milk_cat/`
   檔名：`milk_cat_pose_death_fly_v1.png`
   Prompt：`請生成 1024x1024、透明背景的像素風戰鬥角色動作定稿圖；角色是一隻可愛的牛奶色擬人化貓咪，雙腳站立，白色帶奶油色毛皮，身形稍微圓潤，神情溫和但可靠；動作為死亡擊飛，要求被打飛、翻滾或騰空，誇張但不血腥；必須維持同一隻角色。`

10. 存放位置：`assets/sprites/battle/cats/milk_cat/`
    檔名：`milk_cat_idle_right.png`
    Prompt：`請生成透明背景橫向 sprite sheet，6 格動畫，每格 160x160，總尺寸 960x160；角色朝右；角色是一隻可愛的牛奶色擬人化貓咪，雙腳站立，白色帶奶油色毛皮，身形稍微圓潤，神情溫和但可靠；動作是待機，要求站姿穩定、有守護感；6 格維持同一隻角色；風格必須是像素風、Q版。`

11. 存放位置：`assets/sprites/battle/cats/milk_cat/`
    檔名：`milk_cat_run_right.png`
    Prompt：`請生成透明背景橫向 sprite sheet，6 格動畫，每格 160x160，總尺寸 960x160；角色朝右；角色是一隻可愛的牛奶色擬人化貓咪，雙腳站立，白色帶奶油色毛皮，身形稍微圓潤，神情溫和但可靠；動作是跑步，要求步伐穩重但不笨重；6 格維持同一隻角色；風格必須是像素風、Q版。`

12. 存放位置：`assets/sprites/battle/cats/milk_cat/`
    檔名：`milk_cat_collide_right.png`
    Prompt：`請生成透明背景橫向 sprite sheet，6 格動畫，每格 160x160，總尺寸 960x160；角色朝右；角色是一隻可愛的牛奶色擬人化貓咪，雙腳站立，白色帶奶油色毛皮，身形稍微圓潤，神情溫和但可靠；動作是撞擊，要求像厚實防守角色的短距離撞擊；6 格維持同一隻角色；風格必須是像素風、Q版。`

13. 存放位置：`assets/sprites/battle/cats/milk_cat/`
    檔名：`milk_cat_knockback_right.png`
    Prompt：`請生成透明背景橫向 sprite sheet，6 格動畫，每格 160x160，總尺寸 960x160；角色朝右；角色是一隻可愛的牛奶色擬人化貓咪，雙腳站立，白色帶奶油色毛皮，身形稍微圓潤，神情溫和但可靠；動作是擊退，要求厚實身形被撞開、仍有重量感；6 格維持同一隻角色；風格必須是像素風、Q版。`

14. 存放位置：`assets/sprites/battle/cats/milk_cat/`
    檔名：`milk_cat_stagger_right.png`
    Prompt：`請生成透明背景橫向 sprite sheet，6 格動畫，每格 160x160，總尺寸 960x160；角色朝右；角色是一隻可愛的牛奶色擬人化貓咪，雙腳站立，白色帶奶油色毛皮，身形稍微圓潤，神情溫和但可靠；動作是受創踉蹌，要求被打後仍努力穩住姿勢；6 格維持同一隻角色；風格必須是像素風、Q版。`

15. 存放位置：`assets/sprites/battle/cats/milk_cat/`
    檔名：`milk_cat_skill_right.png`
    Prompt：`請生成透明背景橫向 sprite sheet，6 格動畫，每格 160x160，總尺寸 960x160；角色朝右；角色是一隻可愛的牛奶色擬人化貓咪，雙腳站立，白色帶奶油色毛皮，身形稍微圓潤，神情溫和但可靠；動作是技能施放，要求像舉起護盾或展開保護姿勢；6 格維持同一隻角色；風格必須是像素風、Q版。`

16. 存放位置：`assets/sprites/battle/cats/milk_cat/`
    檔名：`milk_cat_death_fly_right.png`
    Prompt：`請生成透明背景橫向 sprite sheet，6 格動畫，每格 160x160，總尺寸 960x160；角色朝右；角色是一隻可愛的牛奶色擬人化貓咪，雙腳站立，白色帶奶油色毛皮，身形稍微圓潤，神情溫和但可靠；動作是死亡擊飛，要求被打飛後翻滾或騰空，誇張但不血腥；6 格維持同一隻角色；風格必須是像素風、Q版。`

### `ninja_cat`

角色固定描述：

`一隻可愛的忍者風擬人化貓咪，雙腳站立，深色毛皮，紅色圍巾，眼神銳利，身形輕巧敏捷，像高速刺客型角色。`

1. 存放位置：`assets/sprites/ui/character_refs/ninja_cat/`
   檔名：`ninja_cat_ref_front_v1.png`
   Prompt：`請生成 1024x1024、透明背景的像素風角色定稿圖；角色是一隻可愛的忍者風擬人化貓咪，雙腳站立，深色毛皮，紅色圍巾，眼神銳利，身形輕巧敏捷，像高速刺客型角色；視角為正面站立；全身完整入鏡；風格必須是像素風、可愛擬人化、雙腳站立、Q版戰鬥角色。`

2. 存放位置：`assets/sprites/ui/character_refs/ninja_cat/`
   檔名：`ninja_cat_ref_right_v1.png`
   Prompt：`請生成 1024x1024、透明背景的像素風角色定稿圖；角色是一隻可愛的忍者風擬人化貓咪，雙腳站立，深色毛皮，紅色圍巾，眼神銳利，身形輕巧敏捷，像高速刺客型角色；視角為右側站立；全身完整入鏡；風格必須是像素風、可愛擬人化、雙腳站立、Q版戰鬥角色。`

3. 存放位置：`assets/sprites/ui/character_refs/ninja_cat/`
   檔名：`ninja_cat_ref_three_quarter_v1.png`
   Prompt：`請生成 1024x1024、透明背景的像素風角色定稿圖；角色是一隻可愛的忍者風擬人化貓咪，雙腳站立，深色毛皮，紅色圍巾，眼神銳利，身形輕巧敏捷，像高速刺客型角色；視角為 3/4 側站立；全身完整入鏡；風格必須是像素風、可愛擬人化、雙腳站立、Q版戰鬥角色。`

4. 存放位置：`assets/sprites/ui/character_refs/ninja_cat/`
   檔名：`ninja_cat_icon_v1.png`
   Prompt：`請生成 256x256、透明背景的手機遊戲角色頭像；角色是一隻可愛的忍者風擬人化貓咪，雙腳站立角色語言，深色毛皮，紅色圍巾，眼神銳利，身形輕巧敏捷，像高速刺客型角色；構圖為頭像或半身像置中；風格必須是像素風、可愛擬人化、Q版。`

5. 存放位置：`assets/sprites/ui/character_refs/ninja_cat/`
   檔名：`ninja_cat_pose_idle_v1.png`
   Prompt：`請生成 1024x1024、透明背景的像素風戰鬥角色動作定稿圖；角色是一隻可愛的忍者風擬人化貓咪，雙腳站立，深色毛皮，紅色圍巾，眼神銳利，身形輕巧敏捷；動作為待機，要求姿勢壓低、像隨時準備突襲；必須維持同一隻角色。`

6. 存放位置：`assets/sprites/ui/character_refs/ninja_cat/`
   檔名：`ninja_cat_pose_run_v1.png`
   Prompt：`請生成 1024x1024、透明背景的像素風戰鬥角色動作定稿圖；角色是一隻可愛的忍者風擬人化貓咪，雙腳站立，深色毛皮，紅色圍巾，眼神銳利，身形輕巧敏捷；動作為跑步，要求速度感強、步伐輕、像刺客高速位移；必須維持同一隻角色。`

7. 存放位置：`assets/sprites/ui/character_refs/ninja_cat/`
   檔名：`ninja_cat_pose_stagger_v1.png`
   Prompt：`請生成 1024x1024、透明背景的像素風戰鬥角色動作定稿圖；角色是一隻可愛的忍者風擬人化貓咪，雙腳站立，深色毛皮，紅色圍巾，眼神銳利，身形輕巧敏捷；動作為受創踉蹌，要求短暫失衡、仍保有敏捷感；必須維持同一隻角色。`

8. 存放位置：`assets/sprites/ui/character_refs/ninja_cat/`
   檔名：`ninja_cat_pose_skill_v1.png`
   Prompt：`請生成 1024x1024、透明背景的像素風戰鬥角色動作定稿圖；角色是一隻可愛的忍者風擬人化貓咪，雙腳站立，深色毛皮，紅色圍巾，眼神銳利，身形輕巧敏捷；動作為技能施放，要求像影分身斬或瞬間突刺；必須維持同一隻角色。`

9. 存放位置：`assets/sprites/ui/character_refs/ninja_cat/`
   檔名：`ninja_cat_pose_death_fly_v1.png`
   Prompt：`請生成 1024x1024、透明背景的像素風戰鬥角色動作定稿圖；角色是一隻可愛的忍者風擬人化貓咪，雙腳站立，深色毛皮，紅色圍巾，眼神銳利，身形輕巧敏捷；動作為死亡擊飛，要求被打飛、翻滾或騰空，誇張但不血腥；必須維持同一隻角色。`

10. 存放位置：`assets/sprites/battle/cats/ninja_cat/`
    檔名：`ninja_cat_idle_right.png`
    Prompt：`請生成透明背景橫向 sprite sheet，6 格動畫，每格 160x160，總尺寸 960x160；角色朝右；角色是一隻可愛的忍者風擬人化貓咪，雙腳站立，深色毛皮，紅色圍巾，眼神銳利，身形輕巧敏捷；動作是待機，要求低重心、安靜、像隨時準備突襲；6 格維持同一隻角色；風格必須是像素風、Q版。`

11. 存放位置：`assets/sprites/battle/cats/ninja_cat/`
    檔名：`ninja_cat_run_right.png`
    Prompt：`請生成透明背景橫向 sprite sheet，6 格動畫，每格 160x160，總尺寸 960x160；角色朝右；角色是一隻可愛的忍者風擬人化貓咪，雙腳站立，深色毛皮，紅色圍巾，眼神銳利，身形輕巧敏捷；動作是跑步，要求速度感很強、輕巧、敏捷；6 格維持同一隻角色；風格必須是像素風、Q版。`

12. 存放位置：`assets/sprites/battle/cats/ninja_cat/`
    檔名：`ninja_cat_collide_right.png`
    Prompt：`請生成透明背景橫向 sprite sheet，6 格動畫，每格 160x160，總尺寸 960x160；角色朝右；角色是一隻可愛的忍者風擬人化貓咪，雙腳站立，深色毛皮，紅色圍巾，眼神銳利，身形輕巧敏捷；動作是撞擊，要求像刺客瞬間貼身命中的短爆發；6 格維持同一隻角色；風格必須是像素風、Q版。`

13. 存放位置：`assets/sprites/battle/cats/ninja_cat/`
    檔名：`ninja_cat_knockback_right.png`
    Prompt：`請生成透明背景橫向 sprite sheet，6 格動畫，每格 160x160，總尺寸 960x160；角色朝右；角色是一隻可愛的忍者風擬人化貓咪，雙腳站立，深色毛皮，紅色圍巾，眼神銳利，身形輕巧敏捷；動作是擊退，要求被撞開後向後飛退、失去重心；6 格維持同一隻角色；風格必須是像素風、Q版。`

14. 存放位置：`assets/sprites/battle/cats/ninja_cat/`
    檔名：`ninja_cat_stagger_right.png`
    Prompt：`請生成透明背景橫向 sprite sheet，6 格動畫，每格 160x160，總尺寸 960x160；角色朝右；角色是一隻可愛的忍者風擬人化貓咪，雙腳站立，深色毛皮，紅色圍巾，眼神銳利，身形輕巧敏捷；動作是受創踉蹌，要求暈眩但仍保有輕巧角色輪廓；6 格維持同一隻角色；風格必須是像素風、Q版。`

15. 存放位置：`assets/sprites/battle/cats/ninja_cat/`
    檔名：`ninja_cat_skill_right.png`
    Prompt：`請生成透明背景橫向 sprite sheet，6 格動畫，每格 160x160，總尺寸 960x160；角色朝右；角色是一隻可愛的忍者風擬人化貓咪，雙腳站立，深色毛皮，紅色圍巾，眼神銳利，身形輕巧敏捷；動作是技能施放，要求像影分身斬、瞬斬、突刺；6 格維持同一隻角色；風格必須是像素風、Q版。`

16. 存放位置：`assets/sprites/battle/cats/ninja_cat/`
    檔名：`ninja_cat_death_fly_right.png`
    Prompt：`請生成透明背景橫向 sprite sheet，6 格動畫，每格 160x160，總尺寸 960x160；角色朝右；角色是一隻可愛的忍者風擬人化貓咪，雙腳站立，深色毛皮，紅色圍巾，眼神銳利，身形輕巧敏捷；動作是死亡擊飛，要求被打飛後翻滾或騰空，誇張但不血腥；6 格維持同一隻角色；風格必須是像素風、Q版。`

### `orange_cat`

角色固定描述：

`一隻可愛的橘色虎斑擬人化貓咪，雙腳站立，橘色條紋毛皮，表情自信又衝動，身形結實，像喜歡正面衝撞的力量型角色。`

1. 存放位置：`assets/sprites/ui/character_refs/orange_cat/`
   檔名：`orange_cat_ref_front_v1.png`
   Prompt：`請生成 1024x1024、透明背景的像素風角色定稿圖；角色是一隻可愛的橘色虎斑擬人化貓咪，雙腳站立，橘色條紋毛皮，表情自信又衝動，身形結實，像喜歡正面衝撞的力量型角色；視角為正面站立；全身完整入鏡；風格必須是像素風、可愛擬人化、雙腳站立、Q版戰鬥角色。`

2. 存放位置：`assets/sprites/ui/character_refs/orange_cat/`
   檔名：`orange_cat_ref_right_v1.png`
   Prompt：`請生成 1024x1024、透明背景的像素風角色定稿圖；角色是一隻可愛的橘色虎斑擬人化貓咪，雙腳站立，橘色條紋毛皮，表情自信又衝動，身形結實，像喜歡正面衝撞的力量型角色；視角為右側站立；全身完整入鏡；風格必須是像素風、可愛擬人化、雙腳站立、Q版戰鬥角色。`

3. 存放位置：`assets/sprites/ui/character_refs/orange_cat/`
   檔名：`orange_cat_ref_three_quarter_v1.png`
   Prompt：`請生成 1024x1024、透明背景的像素風角色定稿圖；角色是一隻可愛的橘色虎斑擬人化貓咪，雙腳站立，橘色條紋毛皮，表情自信又衝動，身形結實，像喜歡正面衝撞的力量型角色；視角為 3/4 側站立；全身完整入鏡；風格必須是像素風、可愛擬人化、雙腳站立、Q版戰鬥角色。`

4. 存放位置：`assets/sprites/ui/character_refs/orange_cat/`
   檔名：`orange_cat_icon_v1.png`
   Prompt：`請生成 256x256、透明背景的手機遊戲角色頭像；角色是一隻可愛的橘色虎斑擬人化貓咪，雙腳站立角色語言，橘色條紋毛皮，表情自信又衝動，身形結實，像喜歡正面衝撞的力量型角色；構圖為頭像或半身像置中；風格必須是像素風、可愛擬人化、Q版。`

5. 存放位置：`assets/sprites/ui/character_refs/orange_cat/`
   檔名：`orange_cat_pose_idle_v1.png`
   Prompt：`請生成 1024x1024、透明背景的像素風戰鬥角色動作定稿圖；角色是一隻可愛的橘色虎斑擬人化貓咪，雙腳站立，橘色條紋毛皮，表情自信又衝動，身形結實；動作為待機，要求站姿厚實、像準備往前撞；必須維持同一隻角色。`

6. 存放位置：`assets/sprites/ui/character_refs/orange_cat/`
   檔名：`orange_cat_pose_run_v1.png`
   Prompt：`請生成 1024x1024、透明背景的像素風戰鬥角色動作定稿圖；角色是一隻可愛的橘色虎斑擬人化貓咪，雙腳站立，橘色條紋毛皮，表情自信又衝動，身形結實；動作為跑步，要求大步衝刺、前傾、帶重量感；必須維持同一隻角色。`

7. 存放位置：`assets/sprites/ui/character_refs/orange_cat/`
   檔名：`orange_cat_pose_stagger_v1.png`
   Prompt：`請生成 1024x1024、透明背景的像素風戰鬥角色動作定稿圖；角色是一隻可愛的橘色虎斑擬人化貓咪，雙腳站立，橘色條紋毛皮，表情自信又衝動，身形結實；動作為受創踉蹌，要求力量感角色失衡的瞬間；必須維持同一隻角色。`

8. 存放位置：`assets/sprites/ui/character_refs/orange_cat/`
   檔名：`orange_cat_pose_skill_v1.png`
   Prompt：`請生成 1024x1024、透明背景的像素風戰鬥角色動作定稿圖；角色是一隻可愛的橘色虎斑擬人化貓咪，雙腳站立，橘色條紋毛皮，表情自信又衝動，身形結實；動作為技能施放，要求像橫衝直撞、重擊、爆發式正面突進；必須維持同一隻角色。`

9. 存放位置：`assets/sprites/ui/character_refs/orange_cat/`
   檔名：`orange_cat_pose_death_fly_v1.png`
   Prompt：`請生成 1024x1024、透明背景的像素風戰鬥角色動作定稿圖；角色是一隻可愛的橘色虎斑擬人化貓咪，雙腳站立，橘色條紋毛皮，表情自信又衝動，身形結實；動作為死亡擊飛，要求被打飛、翻滾或騰空，誇張但不血腥；必須維持同一隻角色。`

10. 存放位置：`assets/sprites/battle/cats/orange_cat/`
    檔名：`orange_cat_idle_right.png`
    Prompt：`請生成透明背景橫向 sprite sheet，6 格動畫，每格 160x160，總尺寸 960x160；角色朝右；角色是一隻可愛的橘色虎斑擬人化貓咪，雙腳站立，橘色條紋毛皮，表情自信又衝動，身形結實；動作是待機，要求站姿厚實、像準備發動衝撞；6 格維持同一隻角色；風格必須是像素風、Q版。`

11. 存放位置：`assets/sprites/battle/cats/orange_cat/`
    檔名：`orange_cat_run_right.png`
    Prompt：`請生成透明背景橫向 sprite sheet，6 格動畫，每格 160x160，總尺寸 960x160；角色朝右；角色是一隻可愛的橘色虎斑擬人化貓咪，雙腳站立，橘色條紋毛皮，表情自信又衝動，身形結實；動作是跑步，要求大步衝刺、前傾、重量感明顯；6 格維持同一隻角色；風格必須是像素風、Q版。`

12. 存放位置：`assets/sprites/battle/cats/orange_cat/`
    檔名：`orange_cat_collide_right.png`
    Prompt：`請生成透明背景橫向 sprite sheet，6 格動畫，每格 160x160，總尺寸 960x160；角色朝右；角色是一隻可愛的橘色虎斑擬人化貓咪，雙腳站立，橘色條紋毛皮，表情自信又衝動，身形結實；動作是撞擊，要求像正面重撞、爆發力強、衝擊感大；6 格維持同一隻角色；風格必須是像素風、Q版。`

13. 存放位置：`assets/sprites/battle/cats/orange_cat/`
    檔名：`orange_cat_knockback_right.png`
    Prompt：`請生成透明背景橫向 sprite sheet，6 格動畫，每格 160x160，總尺寸 960x160；角色朝右；角色是一隻可愛的橘色虎斑擬人化貓咪，雙腳站立，橘色條紋毛皮，表情自信又衝動，身形結實；動作是擊退，要求重型角色被撞開、後仰、飛退；6 格維持同一隻角色；風格必須是像素風、Q版。`

14. 存放位置：`assets/sprites/battle/cats/orange_cat/`
    檔名：`orange_cat_stagger_right.png`
    Prompt：`請生成透明背景橫向 sprite sheet，6 格動畫，每格 160x160，總尺寸 960x160；角色朝右；角色是一隻可愛的橘色虎斑擬人化貓咪，雙腳站立，橘色條紋毛皮，表情自信又衝動，身形結實；動作是受創踉蹌，要求厚實角色被打到後腳步不穩；6 格維持同一隻角色；風格必須是像素風、Q版。`

15. 存放位置：`assets/sprites/battle/cats/orange_cat/`
    檔名：`orange_cat_skill_right.png`
    Prompt：`請生成透明背景橫向 sprite sheet，6 格動畫，每格 160x160，總尺寸 960x160；角色朝右；角色是一隻可愛的橘色虎斑擬人化貓咪，雙腳站立，橘色條紋毛皮，表情自信又衝動，身形結實；動作是技能施放，要求像橫衝直撞與重擊的爆發姿勢；6 格維持同一隻角色；風格必須是像素風、Q版。`

16. 存放位置：`assets/sprites/battle/cats/orange_cat/`
    檔名：`orange_cat_death_fly_right.png`
    Prompt：`請生成透明背景橫向 sprite sheet，6 格動畫，每格 160x160，總尺寸 960x160；角色朝右；角色是一隻可愛的橘色虎斑擬人化貓咪，雙腳站立，橘色條紋毛皮，表情自信又衝動，身形結實；動作是死亡擊飛，要求被打飛後翻滾或騰空，誇張但不血腥；6 格維持同一隻角色；風格必須是像素風、Q版。`

### `tuxedo_cat`

角色固定描述：

`一隻可愛的賓士擬人化貓咪，雙腳站立，黑白相間毛皮，表情聰明冷靜，帶有優雅決鬥者氣質，像擅長反擊與抓時機的角色。`

1. 存放位置：`assets/sprites/ui/character_refs/tuxedo_cat/`
   檔名：`tuxedo_cat_ref_front_v1.png`
   Prompt：`請生成 1024x1024、透明背景的像素風角色定稿圖；角色是一隻可愛的賓士擬人化貓咪，雙腳站立，黑白相間毛皮，表情聰明冷靜，帶有優雅決鬥者氣質，像擅長反擊與抓時機的角色；視角為正面站立；全身完整入鏡；風格必須是像素風、可愛擬人化、雙腳站立、Q版戰鬥角色。`

2. 存放位置：`assets/sprites/ui/character_refs/tuxedo_cat/`
   檔名：`tuxedo_cat_ref_right_v1.png`
   Prompt：`請生成 1024x1024、透明背景的像素風角色定稿圖；角色是一隻可愛的賓士擬人化貓咪，雙腳站立，黑白相間毛皮，表情聰明冷靜，帶有優雅決鬥者氣質，像擅長反擊與抓時機的角色；視角為右側站立；全身完整入鏡；風格必須是像素風、可愛擬人化、雙腳站立、Q版戰鬥角色。`

3. 存放位置：`assets/sprites/ui/character_refs/tuxedo_cat/`
   檔名：`tuxedo_cat_ref_three_quarter_v1.png`
   Prompt：`請生成 1024x1024、透明背景的像素風角色定稿圖；角色是一隻可愛的賓士擬人化貓咪，雙腳站立，黑白相間毛皮，表情聰明冷靜，帶有優雅決鬥者氣質，像擅長反擊與抓時機的角色；視角為 3/4 側站立；全身完整入鏡；風格必須是像素風、可愛擬人化、雙腳站立、Q版戰鬥角色。`

4. 存放位置：`assets/sprites/ui/character_refs/tuxedo_cat/`
   檔名：`tuxedo_cat_icon_v1.png`
   Prompt：`請生成 256x256、透明背景的手機遊戲角色頭像；角色是一隻可愛的賓士擬人化貓咪，雙腳站立角色語言，黑白相間毛皮，表情聰明冷靜，帶有優雅決鬥者氣質，像擅長反擊與抓時機的角色；構圖為頭像或半身像置中；風格必須是像素風、可愛擬人化、Q版。`

5. 存放位置：`assets/sprites/ui/character_refs/tuxedo_cat/`
   檔名：`tuxedo_cat_pose_idle_v1.png`
   Prompt：`請生成 1024x1024、透明背景的像素風戰鬥角色動作定稿圖；角色是一隻可愛的賓士擬人化貓咪，雙腳站立，黑白相間毛皮，表情聰明冷靜，帶有優雅決鬥者氣質；動作為待機，要求從容、穩定、像準備抓反擊時機；必須維持同一隻角色。`

6. 存放位置：`assets/sprites/ui/character_refs/tuxedo_cat/`
   檔名：`tuxedo_cat_pose_run_v1.png`
   Prompt：`請生成 1024x1024、透明背景的像素風戰鬥角色動作定稿圖；角色是一隻可愛的賓士擬人化貓咪，雙腳站立，黑白相間毛皮，表情聰明冷靜，帶有優雅決鬥者氣質；動作為跑步，要求步伐俐落、節奏穩、姿態乾淨；必須維持同一隻角色。`

7. 存放位置：`assets/sprites/ui/character_refs/tuxedo_cat/`
   檔名：`tuxedo_cat_pose_stagger_v1.png`
   Prompt：`請生成 1024x1024、透明背景的像素風戰鬥角色動作定稿圖；角色是一隻可愛的賓士擬人化貓咪，雙腳站立，黑白相間毛皮，表情聰明冷靜，帶有優雅決鬥者氣質；動作為受創踉蹌，要求被打中後稍微失去平衡，但仍保持優雅輪廓；必須維持同一隻角色。`

8. 存放位置：`assets/sprites/ui/character_refs/tuxedo_cat/`
   檔名：`tuxedo_cat_pose_skill_v1.png`
   Prompt：`請生成 1024x1024、透明背景的像素風戰鬥角色動作定稿圖；角色是一隻可愛的賓士擬人化貓咪，雙腳站立，黑白相間毛皮，表情聰明冷靜，帶有優雅決鬥者氣質；動作為技能施放，要求像看準時機後的反擊姿勢；必須維持同一隻角色。`

9. 存放位置：`assets/sprites/ui/character_refs/tuxedo_cat/`
   檔名：`tuxedo_cat_pose_death_fly_v1.png`
   Prompt：`請生成 1024x1024、透明背景的像素風戰鬥角色動作定稿圖；角色是一隻可愛的賓士擬人化貓咪，雙腳站立，黑白相間毛皮，表情聰明冷靜，帶有優雅決鬥者氣質；動作為死亡擊飛，要求被打飛、翻滾或騰空，誇張但不血腥；必須維持同一隻角色。`

10. 存放位置：`assets/sprites/battle/cats/tuxedo_cat/`
    檔名：`tuxedo_cat_idle_right.png`
    Prompt：`請生成透明背景橫向 sprite sheet，6 格動畫，每格 160x160，總尺寸 960x160；角色朝右；角色是一隻可愛的賓士擬人化貓咪，雙腳站立，黑白相間毛皮，表情聰明冷靜，帶有優雅決鬥者氣質；動作是待機，要求從容、穩定、像準備抓反擊時機；6 格維持同一隻角色；風格必須是像素風、Q版。`

11. 存放位置：`assets/sprites/battle/cats/tuxedo_cat/`
    檔名：`tuxedo_cat_run_right.png`
    Prompt：`請生成透明背景橫向 sprite sheet，6 格動畫，每格 160x160，總尺寸 960x160；角色朝右；角色是一隻可愛的賓士擬人化貓咪，雙腳站立，黑白相間毛皮，表情聰明冷靜，帶有優雅決鬥者氣質；動作是跑步，要求步伐俐落乾淨、節奏穩定；6 格維持同一隻角色；風格必須是像素風、Q版。`

12. 存放位置：`assets/sprites/battle/cats/tuxedo_cat/`
    檔名：`tuxedo_cat_collide_right.png`
    Prompt：`請生成透明背景橫向 sprite sheet，6 格動畫，每格 160x160，總尺寸 960x160；角色朝右；角色是一隻可愛的賓士擬人化貓咪，雙腳站立，黑白相間毛皮，表情聰明冷靜，帶有優雅決鬥者氣質；動作是撞擊，要求像看準時機後的精準命中；6 格維持同一隻角色；風格必須是像素風、Q版。`

13. 存放位置：`assets/sprites/battle/cats/tuxedo_cat/`
    檔名：`tuxedo_cat_knockback_right.png`
    Prompt：`請生成透明背景橫向 sprite sheet，6 格動畫，每格 160x160，總尺寸 960x160；角色朝右；角色是一隻可愛的賓士擬人化貓咪，雙腳站立，黑白相間毛皮，表情聰明冷靜，帶有優雅決鬥者氣質；動作是擊退，要求被撞開後後仰飛退、節奏清楚；6 格維持同一隻角色；風格必須是像素風、Q版。`

14. 存放位置：`assets/sprites/battle/cats/tuxedo_cat/`
    檔名：`tuxedo_cat_stagger_right.png`
    Prompt：`請生成透明背景橫向 sprite sheet，6 格動畫，每格 160x160，總尺寸 960x160；角色朝右；角色是一隻可愛的賓士擬人化貓咪，雙腳站立，黑白相間毛皮，表情聰明冷靜，帶有優雅決鬥者氣質；動作是受創踉蹌，要求被命中後短暫失衡但仍保有決鬥者輪廓；6 格維持同一隻角色；風格必須是像素風、Q版。`

15. 存放位置：`assets/sprites/battle/cats/tuxedo_cat/`
    檔名：`tuxedo_cat_skill_right.png`
    Prompt：`請生成透明背景橫向 sprite sheet，6 格動畫，每格 160x160，總尺寸 960x160；角色朝右；角色是一隻可愛的賓士擬人化貓咪，雙腳站立，黑白相間毛皮，表情聰明冷靜，帶有優雅決鬥者氣質；動作是技能施放，要求像精準反擊、抓破綻、架勢乾淨俐落；6 格維持同一隻角色；風格必須是像素風、Q版。`

16. 存放位置：`assets/sprites/battle/cats/tuxedo_cat/`
    檔名：`tuxedo_cat_death_fly_right.png`
    Prompt：`請生成透明背景橫向 sprite sheet，6 格動畫，每格 160x160，總尺寸 960x160；角色朝右；角色是一隻可愛的賓士擬人化貓咪，雙腳站立，黑白相間毛皮，表情聰明冷靜，帶有優雅決鬥者氣質；動作是死亡擊飛，要求被打飛後翻滾或騰空，誇張但不血腥；6 格維持同一隻角色；風格必須是像素風、Q版。`

## B. 主功能頁背景圖

### 共用背景 Prompt 規則

```text
請生成 720x1280 的手機遊戲 UI 背景圖。
風格為像素風、溫暖家居感、可愛但不幼稚、適合貓咪主題遊戲。
畫面需要保留上方標題區、中間資訊區、下方按鈕區的留白，不要塞滿，不要文字，不要 logo，不要浮水印。
不要科幻、不要霓虹、不要厚塗、不要寫實攝影。
```

1. 存放位置：`assets/sprites/ui/`
   檔名：`activity_background_v1.png`
   Prompt：`請生成 720x1280 的手機遊戲 UI 背景圖；主題是活動頁背景，像貓咪公寓中的活動佈告走廊，有任務海報、溫暖木地板、布告欄、可愛活動感；風格為像素風、溫暖家居感、可愛但不幼稚，保留上中下 UI 留白，不要文字、logo、浮水印。`

2. 存放位置：`assets/sprites/ui/`
   檔名：`config_background_v1.png`
   Prompt：`請生成 720x1280 的手機遊戲 UI 背景圖；主題是隊伍配置頁背景，像貓咪戰術房間，有小白板、靠墊、隊伍筆記、暖色收納櫃；風格為像素風、溫暖家居感、可愛但不幼稚，保留上中下 UI 留白，不要文字、logo、浮水印。`

3. 存放位置：`assets/sprites/ui/`
   檔名：`enhance_background_v1.png`
   Prompt：`請生成 720x1280 的手機遊戲 UI 背景圖；主題是強化頁背景，像餵食與照護角落，有木桌、飼料罐、毛刷、暖燈、升級工作台感；風格為像素風、溫暖家居感、可愛但不幼稚，保留上中下 UI 留白，不要文字、logo、浮水印。`

4. 存放位置：`assets/sprites/ui/`
   檔名：`dungeon_background_v1.png`
   Prompt：`請生成 720x1280 的手機遊戲 UI 背景圖；主題是地城入口頁背景，像紙箱迷宮與家中儲藏角落混合的冒險入口，有探索感但仍可愛；風格為像素風、溫暖家居感、可愛但不幼稚，保留上中下 UI 留白，不要文字、logo、浮水印。`

5. 存放位置：`assets/sprites/ui/`
   檔名：`arena_background_v1.png`
   Prompt：`請生成 720x1280 的手機遊戲 UI 背景圖；主題是競技場頁背景，像客廳裡搭出來的比賽場，有玩具障礙、看板、家居競技氣氛；風格為像素風、溫暖家居感、可愛但不幼稚，保留上中下 UI 留白，不要文字、logo、浮水印。`

6. 存放位置：`assets/sprites/ui/`
   檔名：`scooper_background_v1.png`
   Prompt：`請生成 720x1280 的手機遊戲 UI 背景圖；主題是鏟屎官系統頁背景，像收藏工作室與貓咪生活紀錄牆，有照片、抽屜、收藏盒、筆記板；風格為像素風、溫暖家居感、可愛但不幼稚，保留上中下 UI 留白，不要文字、logo、浮水印。`

7. 存放位置：`assets/sprites/ui/`
   檔名：`shop_background_v1.png`
   Prompt：`請生成 720x1280 的手機遊戲 UI 背景圖；主題是商店頁背景，像公寓角落裡的貓咪商店，有貨架、誘捕籠、寶物展示台、溫暖市場感；風格為像素風、溫暖家居感、可愛但不幼稚，保留上中下 UI 留白，不要文字、logo、浮水印。`

8. 存放位置：`assets/sprites/ui/`
   檔名：`gacha_background_v1.png`
   Prompt：`請生成 720x1280 的手機遊戲 UI 背景圖；主題是抽卡頁背景，像誘捕籠儀式台與聚光展示角落，有驚喜感但仍保留家居溫度；風格為像素風、溫暖家居感、可愛但不幼稚，保留上中下 UI 留白，不要文字、logo、浮水印。`

9. 存放位置：`assets/sprites/ui/`
   檔名：`mail_background_v1.png`
   Prompt：`請生成 720x1280 的手機遊戲 UI 背景圖；主題是信箱頁背景，像貓咪家中的信件與包裹收納角，有木櫃、信封、包裹盒、通知板；風格為像素風、溫暖家居感、可愛但不幼稚，保留上中下 UI 留白，不要文字、logo、浮水印。`

10. 存放位置：`assets/sprites/ui/`
    檔名：`chat_background_v1.png`
    Prompt：`請生成 720x1280 的手機遊戲 UI 背景圖；主題是聊天頁背景，像貓咪公寓裡的留言牆與休息角落，有軟墊、窗邊、對話感與社群感；風格為像素風、溫暖家居感、可愛但不幼稚，保留上中下 UI 留白，不要文字、logo、浮水印。`

## C. 地城縮圖

1. 存放位置：`assets/sprites/ui/dungeon/`
   檔名：`cat_food.png`
   Prompt：`請生成 256x256、透明背景的像素風地城縮圖；主題是乾糧地下城，像堆滿飼料袋與乾糧桶的可愛地城入口，顏色偏金黃與木色，適合縮圖顯示。`

2. 存放位置：`assets/sprites/ui/dungeon/`
   檔名：`diamond.png`
   Prompt：`請生成 256x256、透明背景的像素風地城縮圖；主題是鑽石地下城，像玻璃櫃與寶石光澤組成的可愛地城入口，帶少量亮藍色點綴但不要科幻。`

3. 存放位置：`assets/sprites/ui/dungeon/`
   檔名：`whisker.png`
   Prompt：`請生成 256x256、透明背景的像素風地城縮圖；主題是鬍鬚地下城，像鬍鬚收藏庫與柔軟繩結構成的可愛地城入口，顏色偏灰藍與米色。`

## D. Arena 牌位徽章

1. 存放位置：`assets/sprites/ui/arena_ranks/`
   檔名：`bronze_3.png`
   Prompt：`請生成 256x256、透明背景的像素風競技場牌位徽章，主題是 Bronze III，銅色、最基礎、可愛但正式。`

2. 存放位置：`assets/sprites/ui/arena_ranks/`
   檔名：`bronze_2.png`
   Prompt：`請生成 256x256、透明背景的像素風競技場牌位徽章，主題是 Bronze II，銅色、比 Bronze III 更精緻。`

3. 存放位置：`assets/sprites/ui/arena_ranks/`
   檔名：`bronze_1.png`
   Prompt：`請生成 256x256、透明背景的像素風競技場牌位徽章，主題是 Bronze I，銅色、該段最高階。`

4. 存放位置：`assets/sprites/ui/arena_ranks/`
   檔名：`silver_3.png`
   Prompt：`請生成 256x256、透明背景的像素風競技場牌位徽章，主題是 Silver III，銀色、可愛但正式。`

5. 存放位置：`assets/sprites/ui/arena_ranks/`
   檔名：`silver_2.png`
   Prompt：`請生成 256x256、透明背景的像素風競技場牌位徽章，主題是 Silver II，銀色、比 Silver III 更精緻。`

6. 存放位置：`assets/sprites/ui/arena_ranks/`
   檔名：`silver_1.png`
   Prompt：`請生成 256x256、透明背景的像素風競技場牌位徽章，主題是 Silver I，銀色、該段最高階。`

7. 存放位置：`assets/sprites/ui/arena_ranks/`
   檔名：`gold_3.png`
   Prompt：`請生成 256x256、透明背景的像素風競技場牌位徽章，主題是 Gold III，金色、明亮但不刺眼。`

8. 存放位置：`assets/sprites/ui/arena_ranks/`
   檔名：`gold_2.png`
   Prompt：`請生成 256x256、透明背景的像素風競技場牌位徽章，主題是 Gold II，金色、比 Gold III 更豪華。`

9. 存放位置：`assets/sprites/ui/arena_ranks/`
   檔名：`gold_1.png`
   Prompt：`請生成 256x256、透明背景的像素風競技場牌位徽章，主題是 Gold I，金色、該段最高階。`

10. 存放位置：`assets/sprites/ui/arena_ranks/`
    檔名：`platinum_3.png`
    Prompt：`請生成 256x256、透明背景的像素風競技場牌位徽章，主題是 Platinum III，白金色、乾淨、高級感。`

11. 存放位置：`assets/sprites/ui/arena_ranks/`
    檔名：`platinum_2.png`
    Prompt：`請生成 256x256、透明背景的像素風競技場牌位徽章，主題是 Platinum II，白金色、比 Platinum III 更豪華。`

12. 存放位置：`assets/sprites/ui/arena_ranks/`
    檔名：`platinum_1.png`
    Prompt：`請生成 256x256、透明背景的像素風競技場牌位徽章，主題是 Platinum I，白金色、該段最高階。`

13. 存放位置：`assets/sprites/ui/arena_ranks/`
    檔名：`diamond_3.png`
    Prompt：`請生成 256x256、透明背景的像素風競技場牌位徽章，主題是 Diamond III，藍鑽色、高貴、乾淨。`

14. 存放位置：`assets/sprites/ui/arena_ranks/`
    檔名：`diamond_2.png`
    Prompt：`請生成 256x256、透明背景的像素風競技場牌位徽章，主題是 Diamond II，藍鑽色、比 Diamond III 更華麗。`

15. 存放位置：`assets/sprites/ui/arena_ranks/`
    檔名：`diamond_1.png`
    Prompt：`請生成 256x256、透明背景的像素風競技場牌位徽章，主題是 Diamond I，藍鑽色、該段最高階。`

16. 存放位置：`assets/sprites/ui/arena_ranks/`
    檔名：`master_3.png`
    Prompt：`請生成 256x256、透明背景的像素風競技場牌位徽章，主題是 Master III，深色高階徽章、沉穩、尊榮。`

17. 存放位置：`assets/sprites/ui/arena_ranks/`
    檔名：`master_2.png`
    Prompt：`請生成 256x256、透明背景的像素風競技場牌位徽章，主題是 Master II，深色高階徽章、比 Master III 更華麗。`

18. 存放位置：`assets/sprites/ui/arena_ranks/`
    檔名：`master_1.png`
    Prompt：`請生成 256x256、透明背景的像素風競技場牌位徽章，主題是 Master I，深色高階徽章、該段最高階。`

19. 存放位置：`assets/sprites/ui/arena_ranks/`
    檔名：`elite.png`
    Prompt：`請生成 256x256、透明背景的像素風競技場牌位徽章，主題是 Elite，頂級牌位徽章，獨特、尊榮、最終階，避免俗氣。`

## E. 回憶圖

1. 存放位置：`assets/sprites/ui/memory/`
   檔名：`sunny_nap.png`
   Prompt：`請生成 512x512 的像素風回憶插圖，主題是窗台午睡，暖陽灑進窗邊，一隻貓在窗台安心午睡，氣氛柔和。`

2. 存放位置：`assets/sprites/ui/memory/`
   檔名：`cardboard_hideout.png`
   Prompt：`請生成 512x512 的像素風回憶插圖，主題是紙箱堡壘，剛到貨的紙箱被搭成可愛藏身處，氣氛像童趣冒險。`

3. 存放位置：`assets/sprites/ui/memory/`
   檔名：`midnight_zoomies.png`
   Prompt：`請生成 512x512 的像素風回憶插圖，主題是深夜暴衝，半夜走廊成為貓咪賽道，帶速度感但仍可愛。`

4. 存放位置：`assets/sprites/ui/memory/`
   檔名：`snack_standoff.png`
   Prompt：`請生成 512x512 的像素風回憶插圖，主題是零食對峙，貓咪和零食之間像對決一樣互相盯著，幽默可愛。`

5. 存放位置：`assets/sprites/ui/memory/`
   檔名：`blanket_watch.png`
   Prompt：`請生成 512x512 的像素風回憶插圖，主題是毛毯守夜，一隻貓守著熟悉毛毯與氣味，夜晚安穩溫暖。`

## F. 寶物圖

1. 存放位置：`assets/sprites/ui/treasure/`
   檔名：`gilded_litter_scoop.png`
   Prompt：`請生成 256x256、透明背景的像素風道具圖，主題是鎏金貓砂鏟，精緻金色貓砂鏟，略帶收藏品感，輪廓清楚。`

2. 存放位置：`assets/sprites/ui/treasure/`
   檔名：`moon_chime.png`
   Prompt：`請生成 256x256、透明背景的像素風道具圖，主題是月鈴，一個帶月亮意象的精緻小鈴鐺，柔和神秘、適合高級寶物。`

3. 存放位置：`assets/sprites/ui/treasure/`
   檔名：`bastion_whisker_knot.png`
   Prompt：`請生成 256x256、透明背景的像素風道具圖，主題是堡壘鬍鬚結，粗厚結繩與貓鬍鬚意象結合，帶防禦與守護感。`

4. 存放位置：`assets/sprites/ui/treasure/`
   檔名：`spring_paw_clockwork.png`
   Prompt：`請生成 256x256、透明背景的像素風道具圖，主題是彈簧肉球發條，發條與肉球元素結合，表現速度與彈性。`

5. 存放位置：`assets/sprites/ui/treasure/`
   檔名：`shadow_fang_medal.png`
   Prompt：`請生成 256x256、透明背景的像素風道具圖，主題是影牙勳章，帶利牙與暗色勳章意象，像刺客用高級寶物。`

6. 存放位置：`assets/sprites/ui/treasure/`
   檔名：`velvet_guard_pin.png`
   Prompt：`請生成 256x256、透明背景的像素風道具圖，主題是絨盾別針，柔軟布料與盾牌別針結合，像耐久型守備寶物。`

## G. 貨幣與消耗品 Icon

1. 存放位置：`assets/sprites/ui/rewards/`
   檔名：`gold.png`
   Prompt：`請生成 256x256、透明背景的像素風貨幣 icon，主題是 Gold，金幣堆或金色貨幣袋，清楚好辨識。`

2. 存放位置：`assets/sprites/ui/rewards/`
   檔名：`diamonds.png`
   Prompt：`請生成 256x256、透明背景的像素風貨幣 icon，主題是 Diamonds，藍色寶石或鑽石堆，清楚好辨識。`

3. 存放位置：`assets/sprites/ui/rewards/`
   檔名：`trap_points.png`
   Prompt：`請生成 256x256、透明背景的像素風貨幣 icon，主題是 Trap Points，像誘捕代幣或特殊交換幣，與一般金幣有明顯區別。`

4. 存放位置：`assets/sprites/ui/rewards/`
   檔名：`cat_food.png`
   Prompt：`請生成 256x256、透明背景的像素風消耗品 icon，主題是 Cat Food，飼料顆粒或飼料盆，溫暖可愛。`

5. 存放位置：`assets/sprites/ui/rewards/`
   檔名：`special_cat_food.png`
   Prompt：`請生成 256x256、透明背景的像素風消耗品 icon，主題是 Special Cat Food，高級貓糧，外觀比一般貓糧更珍貴。`

6. 存放位置：`assets/sprites/ui/rewards/`
   檔名：`trap_cages.png`
   Prompt：`請生成 256x256、透明背景的像素風消耗品 icon，主題是 Trap Cages，小型誘捕籠，結構簡化、輪廓清楚。`

7. 存放位置：`assets/sprites/ui/rewards/`
   檔名：`poop_count.png`
   Prompt：`請生成 256x256、透明背景的像素風消耗品 icon，主題是 Poop Count，用幽默、乾淨、不卡髒的可愛方式表現鏟屎資源。`

8. 存放位置：`assets/sprites/ui/rewards/`
   檔名：`memory_shards.png`
   Prompt：`請生成 256x256、透明背景的像素風消耗品 icon，主題是 Memory Shards，像回憶碎片或照片碎片，柔和、有收藏感。`

9. 存放位置：`assets/sprites/ui/rewards/`
   檔名：`whisker_shards.png`
   Prompt：`請生成 256x256、透明背景的像素風消耗品 icon，主題是 Whisker Shards，像鬍鬚碎片或纖細碎片，乾淨、高級。`

## H. Shop 禮包卡面圖

1. 存放位置：`assets/sprites/ui/shop_bundles/`
   檔名：`starter_cleanup_set.png`
   Prompt：`請生成 512x512 的像素風禮包卡面圖，主題是開工清潔組，強調鏟屎官開局成長、暖色家居工作台、帶入門禮包感。`

2. 存放位置：`assets/sprites/ui/shop_bundles/`
   檔名：`night_crit_set.png`
   Prompt：`請生成 512x512 的像素風禮包卡面圖，主題是夜行暴擊組，強調夜色、迅捷、暴擊、刺客型寶物氣氛。`

3. 存放位置：`assets/sprites/ui/shop_bundles/`
   檔名：`frontline_tank_set.png`
   Prompt：`請生成 512x512 的像素風禮包卡面圖，主題是前排硬扛組，強調防禦、厚實、守護、坦克型寶物氣氛。`

4. 存放位置：`assets/sprites/ui/shop_bundles/`
   檔名：`rush_combo_set.png`
   Prompt：`請生成 512x512 的像素風禮包卡面圖，主題是衝刺連發組，強調速度、節奏、快速連續出手。`

5. 存放位置：`assets/sprites/ui/shop_bundles/`
   檔名：`ambush_hunter_set.png`
   Prompt：`請生成 512x512 的像素風禮包卡面圖，主題是暗襲獵手組，強調暗色刺客、爆發、收頭感。`

6. 存放位置：`assets/sprites/ui/shop_bundles/`
   檔名：`guard_tenacity_set.png`
   Prompt：`請生成 512x512 的像素風禮包卡面圖，主題是守備韌性組，強調耐久、站場、長線作戰。`

## I. Gacha 稀有度卡框

1. 存放位置：`assets/sprites/ui/gacha/`
   檔名：`rarity_common_frame_v1.png`
   Prompt：`請生成 512x512、透明背景的像素風抽卡結果卡框，主題是 common，最基本、乾淨、簡單。`

2. 存放位置：`assets/sprites/ui/gacha/`
   檔名：`rarity_uncommon_frame_v1.png`
   Prompt：`請生成 512x512、透明背景的像素風抽卡結果卡框，主題是 uncommon，比 common 稍微更精緻。`

3. 存放位置：`assets/sprites/ui/gacha/`
   檔名：`rarity_fine_frame_v1.png`
   Prompt：`請生成 512x512、透明背景的像素風抽卡結果卡框，主題是 fine，淺藍高級感、但不浮誇。`

4. 存放位置：`assets/sprites/ui/gacha/`
   檔名：`rarity_special_frame_v1.png`
   Prompt：`請生成 512x512、透明背景的像素風抽卡結果卡框，主題是 special，明確比前一階更高級。`

5. 存放位置：`assets/sprites/ui/gacha/`
   檔名：`rarity_precious_frame_v1.png`
   Prompt：`請生成 512x512、透明背景的像素風抽卡結果卡框，主題是 precious，帶收藏價值與高級感。`

6. 存放位置：`assets/sprites/ui/gacha/`
   檔名：`rarity_excellent_frame_v1.png`
   Prompt：`請生成 512x512、透明背景的像素風抽卡結果卡框，主題是 excellent，精緻、亮眼、偏稀有。`

7. 存放位置：`assets/sprites/ui/gacha/`
   檔名：`rarity_rare_frame_v1.png`
   Prompt：`請生成 512x512、透明背景的像素風抽卡結果卡框，主題是 rare，稀有感強、視覺比前一階更有記憶點。`

8. 存放位置：`assets/sprites/ui/gacha/`
   檔名：`rarity_epic_frame_v1.png`
   Prompt：`請生成 512x512、透明背景的像素風抽卡結果卡框，主題是 epic，高稀有、華麗但不俗氣。`

9. 存放位置：`assets/sprites/ui/gacha/`
   檔名：`rarity_legendary_frame_v1.png`
   Prompt：`請生成 512x512、透明背景的像素風抽卡結果卡框，主題是 legendary，頂級稀有、最有儀式感。`

## J. Scooper 裝備 Icon

1. 存放位置：`assets/sprites/ui/scooper_equipment/`
   檔名：`food_bowl.png`
   Prompt：`請生成 256x256、透明背景的像素風裝備 icon，主題是餵食盆，乾淨、可愛、居家。`

2. 存放位置：`assets/sprites/ui/scooper_equipment/`
   檔名：`scratcher.png`
   Prompt：`請生成 256x256、透明背景的像素風裝備 icon，主題是貓抓板，輪廓清楚、好辨識。`

3. 存放位置：`assets/sprites/ui/scooper_equipment/`
   檔名：`teaser_wand.png`
   Prompt：`請生成 256x256、透明背景的像素風裝備 icon，主題是逗貓棒，活潑、有互動感。`

4. 存放位置：`assets/sprites/ui/scooper_equipment/`
   檔名：`grooming_brush.png`
   Prompt：`請生成 256x256、透明背景的像素風裝備 icon，主題是梳毛刷，溫和、照護感。`

5. 存放位置：`assets/sprites/ui/scooper_equipment/`
   檔名：`camera.png`
   Prompt：`請生成 256x256、透明背景的像素風裝備 icon，主題是相機，像記錄貓咪生活用的小相機。`

6. 存放位置：`assets/sprites/ui/scooper_equipment/`
   檔名：`warm_pad.png`
   Prompt：`請生成 256x256、透明背景的像素風裝備 icon，主題是暖墊，柔軟、舒適、保暖。`

7. 存放位置：`assets/sprites/ui/scooper_equipment/`
   檔名：`cardboard_box.png`
   Prompt：`請生成 256x256、透明背景的像素風裝備 icon，主題是紙箱，像貓咪最愛的紙箱藏身處。`

8. 存放位置：`assets/sprites/ui/scooper_equipment/`
   檔名：`toy_doll.png`
   Prompt：`請生成 256x256、透明背景的像素風裝備 icon，主題是玩偶，柔軟可愛、陪伴感。`

## K. Scooper 特殊能力 Icon

1. 存放位置：`assets/sprites/ui/scooper_abilities/`
   檔名：`diligent_scooper.png`
   Prompt：`請生成 256x256、透明背景的像素風能力 icon，主題是勤勞鏟屎官，表現效率提升與勤勞感。`

2. 存放位置：`assets/sprites/ui/scooper_abilities/`
   檔名：`golden_scooper.png`
   Prompt：`請生成 256x256、透明背景的像素風能力 icon，主題是黃金鏟屎官，表現高效率與進階感。`

3. 存放位置：`assets/sprites/ui/scooper_abilities/`
   檔名：`overtime_photo.png`
   Prompt：`請生成 256x256、透明背景的像素風能力 icon，主題是加班執照，表現延長掛機時間。`

4. 存放位置：`assets/sprites/ui/scooper_abilities/`
   檔名：`double_speed.png`
   Prompt：`請生成 256x256、透明背景的像素風能力 icon，主題是雙倍推進，表現戰鬥 2x 加速。`

5. 存放位置：`assets/sprites/ui/scooper_abilities/`
   檔名：`triple_speed.png`
   Prompt：`請生成 256x256、透明背景的像素風能力 icon，主題是三倍推進，表現戰鬥 3x 加速。`

6. 存放位置：`assets/sprites/ui/scooper_abilities/`
   檔名：`instant_finish.png`
   Prompt：`請生成 256x256、透明背景的像素風能力 icon，主題是瞬間收工，表現跳過或快速完成。`

## 備註

- 本文件是以目前 Client / API / dev seed 作為盤點依據；本機沒有直接查到 `MeowParty_Dev` 連線設定，且環境中未提供可直接查 PostgreSQL 的 `psql`，因此 DB 內容以 API schema 與 seed 檔為準。
- 若後續新增 catalog 項目，請同步補上：
  - 檔案位置
  - 檔名
  - 中文 prompt
  - 對應前端使用場景
