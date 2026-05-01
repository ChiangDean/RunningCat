# 29 資產存放與 CDN 分類策略

> Last updated: 2026-04-26
> Audience: Client engineers, technical artists, content artists, release maintainers

---

## 1. 目的

本文件定義 `MeowPartyDashClient` 之後的圖片資產存放策略，解決以下問題：

- Web `index.pck` 容量過大，導致 GitHub Pages / gh-pages 部署失敗。
- UI / preview / 活動圖與戰鬥必需資產混在一起，難以決定哪些應進主包、哪些應走 R2 / CDN。
- 後續製作新圖時，缺少固定資料夾規則，容易再次把大型圖放進主包。

本文件的目標不是只修一次 CI，而是建立長期可維護的分類規則。

---

## 2. 核心原則

### 2.1 分類原則

圖片資產只分成兩種：

1. `Local / Base Pack`
   必須打進 `index.pck`，因為遊戲啟動或核心流程立刻需要。

2. `CDN / Remote Pack`
   可延後載入，應由 R2 / CDN 提供，不應再打進主包。

### 2.2 判斷規則

符合任一條件，放 `Local`：

- 遊戲啟動就會用到
- 首頁首屏就會用到
- 戰鬥場景核心 runtime 立即依賴
- 共用 UI 骨架、框體、底板、mask
- 載不到會直接讓主流程壞掉

符合任一條件，放 `CDN`：

- 大型展示圖、卡面圖、活動圖、preview 圖
- 可在頁面進入後再載入
- 同一類圖會持續新增或替換
- 屬於內容資料，而不是 UI 骨架
- 載不到時可以先用 placeholder / fallback

### 2.3 現階段特殊規則

- `battle` 資產目前全部維持 `Local`
  原因：現有戰鬥流程仍以本地同步載圖為主，尚未完成 preload/cache manager。
- `start_scene_homey_v1.png`、`battle_background_homey_v1.png` 維持 `Local`
  原因：它們屬於啟動與主殼核心背景，不適合先排出主包。

---

## 3. 目標資料夾結構

未來圖片資產應逐步整理成以下結構：

```text
assets/
  sprites/
    local/
      ui/
        start/
        battle_shell/
        common/
        warning/
        oauth/
        core_icons/
      battle/
        cats/
        encounter/
        boss/
    cdn/
      ui/
        character_refs/
        memory/
        cards/
        gacha/
        rewards/
        arena_ranks/
        dungeon/
        home/
        scooper_equipment/
        scooper_abilities/
        treasure/
        activity/
```

### 3.1 `local` 的定位

`assets/sprites/local/` 是主包必需資產，原則上會進 Web export。

### 3.2 `cdn` 的定位

`assets/sprites/cdn/` 是應同步到 R2 的資產，原則上不應進 Web export。

### 3.3 過渡期規則

目前 repo 仍有大量舊路徑，例如：

- `assets/sprites/ui/character_refs/...`
- `assets/sprites/ui/memory/...`
- `assets/sprites/ui/cards/...`
- `assets/sprites/ui/gacha/...`
- `assets/sprites/battle/...`

在正式搬資料夾前，先依照本文件做「邏輯分類」。

也就是：

- 先按文件決定它屬於 `Local` 還是 `CDN`
- 透過 `AssetResolver`、CI sync 白名單、Web export 排除規則落地
- 等路徑穩定後，再做實體資料夾搬移

目前第 1 階段已經先完成實體搬移：

- `assets/sprites/cdn/ui/character_refs/**`
- `assets/sprites/cdn/ui/memory/**`
- `assets/sprites/cdn/ui/cards/**`
- `assets/sprites/cdn/ui/gacha/**`

目前第 2 階段也已完成實體搬移：

- `assets/sprites/cdn/ui/arena_ranks/**`
- `assets/sprites/cdn/ui/dungeon/**`
- `assets/sprites/cdn/ui/scooper_equipment/**`
- `assets/sprites/cdn/ui/scooper_abilities/**`
- `assets/sprites/cdn/ui/treasure/**`
- `assets/sprites/cdn/ui/rewards/{arena_ticket,battle_speed_ticket,cat_food,cat_food_dungeon_ticket,diamond_dungeon_ticket,gold_dungeon_ticket,memory_shards,party_cheer_coupon,poop_dungeon_ticket,special_cat_food,trap_cages,trap_points,whisker_dungeon_ticket,whisker_shards}.png`

目前第 3 階段已完成 activity 類背景與 preview 搬移：

- `assets/sprites/cdn/ui/activity/activity_background_v1.png`
- `assets/sprites/cdn/ui/activity/arena_background_v1.png`
- `assets/sprites/cdn/ui/activity/chat_background_v1.png`
- `assets/sprites/cdn/ui/activity/config_background_v1.png`
- `assets/sprites/cdn/ui/activity/dungeon_background_v1.png`
- `assets/sprites/cdn/ui/activity/enhance_background_v1.png`
- `assets/sprites/cdn/ui/activity/gacha_background_v1.png`
- `assets/sprites/cdn/ui/activity/mail_background_v1.png`
- `assets/sprites/cdn/ui/activity/scooper_background_v1.png`
- `assets/sprites/cdn/ui/activity/shop_background_v1.png`
- `assets/sprites/cdn/ui/activity/combat_trial/sofa_trial_card.svg`

其餘類別仍在過渡期，會先按照本文件做邏輯分類，再逐批搬移。

---

## 4. 現有資產分類結論

### 4.1 必須留在 `Local`

以下內容現階段不要搬到 CDN：

- `assets/sprites/ui/start_scene_homey_v1.png`
- `assets/sprites/ui/battle_background_homey_v1.png`
- `assets/sprites/ui/common/**`
- `assets/sprites/ui/oauth/**`
- `assets/sprites/ui/warning/**`
- `assets/sprites/battle/cats/**`
- `assets/sprites/battle/encounter/**`
- `assets/sprites/battle/boss/**`

原因：

- 啟動首屏與主殼背景屬於核心體驗
- `common/**` 為大量 UI 框體與共用底板
- `battle/**` 雖然已縮圖，但仍是戰鬥必要資產

### 4.2 優先搬到 `CDN`

以下內容是第一批建議搬遷目標：

- `assets/sprites/ui/character_refs/**`
- `assets/sprites/ui/memory/**`
- `assets/sprites/ui/cards/**`
- `assets/sprites/ui/gacha/**`
- `assets/sprites/ui/arena_ranks/**`
- `assets/sprites/ui/dungeon/**`
- `assets/sprites/ui/scooper_equipment/**`
- `assets/sprites/ui/scooper_abilities/**`
- `assets/sprites/ui/treasure/**`
- `assets/sprites/ui/rewards/{arena_ticket,battle_speed_ticket,cat_food,cat_food_dungeon_ticket,diamond_dungeon_ticket,gold_dungeon_ticket,memory_shards,party_cheer_coupon,poop_dungeon_ticket,special_cat_food,trap_cages,trap_points,whisker_dungeon_ticket,whisker_shards}.png`
- `assets/sprites/ui/activity_background_v1.png`
- `assets/sprites/ui/arena_background_v1.png`
- `assets/sprites/ui/chat_background_v1.png`
- `assets/sprites/ui/config_background_v1.png`
- `assets/sprites/ui/dungeon_background_v1.png`
- `assets/sprites/ui/enhance_background_v1.png`
- `assets/sprites/ui/gacha_background_v1.png`
- `assets/sprites/ui/mail_background_v1.png`
- `assets/sprites/ui/scooper_background_v1.png`
- `assets/sprites/ui/shop_background_v1.png`
- `assets/sprites/ui/combat_trial/sofa_trial_card.svg`

### 4.3 條件式搬遷

以下資料夾不能整包搬，必須拆內容：

- `assets/sprites/ui/rewards/**`
  - 已搬 CDN：`arena_ticket.png`、`battle_speed_ticket.png`、`cat_food.png`、`cat_food_dungeon_ticket.png`、`diamond_dungeon_ticket.png`、`gold_dungeon_ticket.png`、`memory_shards.png`、`party_cheer_coupon.png`、`poop_dungeon_ticket.png`、`special_cat_food.png`、`trap_cages.png`、`trap_points.png`、`whisker_dungeon_ticket.png`、`whisker_shards.png`
  - 留本地：`collision_coin.png`、`diamonds.png`、`evil_cat_power_icon.png`、`money.png`、`poop_count.png`、`item_slot_frame_*`、`item_slot_overlay_mask*`

- `assets/sprites/ui/home/**`
  - 可搬：活動入口 preview、展示圖、非首屏裝飾圖
  - 留本地：HUD、首頁核心面板、首屏立即可見資產

- `assets/sprites/ui/activity/**`
  - 已搬 CDN：各功能頁晚載入背景、activity preview 背景、`combat_trial/sofa_trial_card.svg`
  - 留本地：`start_scene_homey_v1.png`、`battle_background_homey_v1.png`、`combat_trial/bath_trial_bg.svg`

- 各功能頁背景圖
  - 可搬：`arena_background_v1.png`、`chat_background_v1.png`、`config_background_v1.png`、`dungeon_background_v1.png`、`enhance_background_v1.png`、`gacha_background_v1.png`、`mail_background_v1.png`、`scooper_background_v1.png`、`shop_background_v1.png`
  - 留本地：`battle_background_homey_v1.png`

---

## 5. 開發與美術放置規則

### 5.1 新圖應放哪裡

如果是以下類型，直接視為 `CDN`：

- 角色 icon / avatar
- 回憶圖
- 卡面圖
- 抽卡展示圖
- 活動 banner
- 商店 bundle 大圖
- 頁面 preview 圖
- 獎勵展示圖
- 不影響主流程的背景裝飾圖

如果是以下類型，直接視為 `Local`：

- StartScene 首屏圖
- BattleScene / HomeShell 核心背景
- 戰鬥 sprite sheet
- 共用 panel / frame / mask / button / function bar
- warning / oauth 等基礎操作流程圖

### 5.2 不確定時的預設規則

如果美術或工程無法快速判定：

- 預設先放 `Local`
- 等功能接完後，再由工程評估是否搬到 `CDN`

不要在不確定的情況下直接丟進 `CDN`，尤其是主流程核心資產。

### 5.3 命名規則

所有可上 CDN 的檔案都應採版本化命名：

- `*_v1.png`
- `*_v2.png`
- `*_v3.png`

不要覆蓋同名檔後期待 CDN 自動更新。

---

## 6. 工程落地規則

### 6.1 `AssetResolver` 是單一入口

對以下類型的 UI 資產，優先走 `AssetResolver`：

- preview texture
- catalog texture
- cat icon
- profile avatar
- background texture

不要在新功能裡直接大量寫：

- `load("res://assets/...")`
- `preload("res://assets/...")`

除非該圖被明確定義為 `Local` 核心資產。

### 6.2 CI / R2 同步規則

最終目標是只同步 `CDN` 資產到 R2，而不是整包 `assets` 全同步。

建議最終同步目標：

- `assets/sprites/cdn/**`

在過渡期，若仍沿用舊路徑，同步規則應改成白名單，而不是整包遞迴：

- `character_refs`
- `memory`
- `cards`
- `gacha`
- `arena_ranks`
- `dungeon`
- `scooper_equipment`
- `scooper_abilities`
- `treasure`
- 指定可搬的 `rewards`、`home`、`activity` 檔案

### 6.3 Web export 規則

只有明確標記為 `CDN` 的資產，才可以從 Web export 排除。

排除前必須先確認：

1. R2 上已有檔案
2. 前端頁面已有 CDN-first + fallback
3. 沒有任何 `preload(...)`、`.tscn ext_resource`、或 parse-time 依賴仍指向該本地檔

---

## 7. 推薦搬遷順序

### 第 1 階段：最低風險、最大回報

- `character_refs`
- `memory`
- `gacha`
- `cards`

### 第 2 階段：catalog / preview 延伸

- `arena_ranks`
- `dungeon`
- `scooper_equipment`
- `scooper_abilities`
- `treasure`
- `rewards` 內的展示 icon

### 第 3 階段：頁面大圖與裝飾圖

- `home` 內非首屏圖
- 活動圖
- 其餘功能頁背景圖

### 第 4 階段：battle 重構後再評估

- `battle/cats`
- `battle/encounter`
- `battle/boss`

這一階段必須先完成：

- battle preload service
- memory cache
- 進場前資產檢查
- fallback / loading UI

在此之前，不要把 battle sprites 視為 CDN 資產。

---

## 8. 一次動工的建議做法

若要按照本文件正式動工，建議順序如下：

1. 在 repo 內建立 `local/` 與 `cdn/` 目標資料夾結構
2. 不先全搬，先從第 1 階段的資料夾開始搬或建立映射
3. 把 CI 從「同步整個 assets」改成「同步 CDN 白名單」
4. 把 Web export 排除規則改成只排 `CDN` 資產
5. 逐頁驗證 preview / avatar / 背景 fallback
6. 文件與實際目錄保持一致，後續所有新圖都按本文件歸類

---

## 9. 簡短結論

本專案之後的穩定規則應該是：

- `Start / Battle / UI 骨架` 放 `Local`
- `預覽圖 / 展示圖 / 活動圖 / 卡面圖 / 角色 icon` 放 `CDN`
- `battle sprites` 在完成 preload/cache 重構前一律放 `Local`
- 美術新增資產時，先按「是否為主流程硬依賴」決定資料夾

不要再用「哪張圖看起來大就先搬」這種一次性判斷，應該按本文件的類型規則執行。

---

## 10. 維運流程

以下流程是之後新增圖片時的標準做法。

### 10.1 新增一張圖時要先判斷什麼

先問自己兩件事：

1. 這張圖是不是主流程一進場就一定要有？
2. 這張圖如果晚 0.5 到 2 秒出現，功能是否仍可接受？

判斷結果：

- 如果是「主流程一定要有」，放 `Local`
- 如果是「可晚載入的展示 / preview / 背景」，放 `CDN`

### 10.2 新圖放置步驟

如果是 `Local`：

1. 放到對應 `assets/sprites/ui/...` 或 `assets/sprites/battle/...`
2. 確認可以安全被 `preload(...)` 或 scene `ext_resource` 使用
3. 不要加入 `cdn_asset_manifest.json` 的 CDN 規則

如果是 `CDN`：

1. 放到對應 `assets/sprites/cdn/ui/...`
2. 優先透過 `AssetResolver` 或既有 helper 接入
3. 視需要補到 `config/cdn_asset_manifest.json`
4. 確認它不屬於 parse-time 必要資產後，才考慮列入 export prune

### 10.3 `cdn_asset_manifest.json` 怎麼用

目前這份 manifest 有兩個重點欄位：

- `cdn_roots`
  給 CI 的 R2 同步白名單使用。只要列在這裡，deploy workflow 就會同步到 R2。
- `export_prune_paths`
  給 Web export 前刪檔使用。只有明確確認安全排除的檔案，才可以放這裡。

規則：

- `cdn_roots` 可以是整個資料夾
- `export_prune_paths` 應該盡量保守，通常是已驗證過的單檔
- 不要把 still-in-use 的 scene 預設圖整包加進 `export_prune_paths`
- 若整個 `cdn_roots` 子資料夾已改成 CDN-first / fallback 載入，且 R2 同步白名單包含同一路徑，可以把該 CDN root 放進 `export_prune_paths`，避免 Web `index.pck` 因大量展示圖超過 GitHub Pages 單檔限制。

### 10.4 什麼情況不能直接加到 `export_prune_paths`

遇到以下任一情況，先不要排除：

- 該圖仍被 `preload(...)` 使用
- 該圖仍被 `.tscn` 的 `ext_resource` 直接引用
- 該頁還沒有 CDN-first fallback
- 還沒確認 R2 已有檔案
- 該圖屬於首屏、戰鬥、主殼 HUD 核心資產

### 10.5 CI 出問題時先看哪裡

如果 deploy 失敗，優先依序檢查：

1. `Sync assets to R2`
   看 manifest 白名單路徑是否存在、R2 secret 是否正常
2. `Remove CDN-managed assets from Web export`
   看是否刪到了仍被 parse-time 依賴的資產
3. `Export Web`
   看 `build/web/index.pck` 最終大小
4. `Deploy to gh-pages`
   若超過 100 MB，代表這輪 prune 還不夠

### 10.6 美術與工程的簡單分工

美術新增資產時：

- 先依本文件判斷 `Local` / `CDN`
- 優先放到正確資料夾，不要先丟 legacy 路徑再等工程搬

工程接線時：

- `Local` 資產可用既有本地載入方式
- `CDN` 資產應優先透過 `AssetResolver` / helper 接入
- 修改完成後，要同步檢查 manifest 與文件是否仍一致
