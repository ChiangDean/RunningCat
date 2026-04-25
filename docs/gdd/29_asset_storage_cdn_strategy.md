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

### 4.3 條件式搬遷

以下資料夾不能整包搬，必須拆內容：

- `assets/sprites/ui/rewards/**`
  - 可搬：大 icon、獎勵展示圖、preview 圖
  - 留本地：`item_slot_frame_*`、`item_slot_overlay_mask`、通用骨架

- `assets/sprites/ui/home/**`
  - 可搬：活動入口 preview、展示圖、非首屏裝飾圖
  - 留本地：HUD、首頁核心面板、首屏立即可見資產

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
