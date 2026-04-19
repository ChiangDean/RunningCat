# 27 - Admin Catalog UI 改版規劃

> 目標：將現有純 JSON 編輯器改為表格/表單式介面，降低操作錯誤率與維護成本。

---

## 一、現況說明

AdminCatalog 目前架構：
- 後端：`AdminCatalogController` → `AdminCatalogService`（12 個 Section）
- 前端：`AdminCatalogScene.gd` 以純 JSON 文字編輯器呈現，無欄位驗證、無結構提示

所有資料一律顯示為原始 JSON，需手動輸入正確 key 名與型別，容易出錯且不易維護。

---

## 二、全部 Catalog 清單（共 22 個實體 / 12 個 Section）

### 分類 A：貓咪相關

| Section | Entity | 主要欄位 | 複雜度 |
|---------|--------|----------|--------|
| **Cats** | CatCatalog | Id, CatKey, CatType, DisplayName, RarityType, BaseHp/Atk/Def/Speed, GachaAvailable, GachaWeight, HpGrowth/AtkGrowth/DefGrowth, IsEnabled, ImagePath | ★★★ |
| **Skills** | SkillCatalog | Id, SkillKey, DisplayName, SkillType, Description, CooldownSeconds, IsEnabled | ★★ |
| **Skills** | （子表）SkillEffectConfig, SkillRankScalingConfig | 效果類型、數值、成長曲線 | ★★★ |
| **Cats** | （子表）CatPassiveSkillConfig, CatActiveSkillConfig | 貓咪技能對應 | ★★ |

### 分類 B：關卡／地下城相關

| Section | Entity | 主要欄位 | 複雜度 |
|---------|--------|----------|--------|
| **Stages** | StageSettingCatalog | Id, ZoneType, EncountersPerBossStage, BossStagesPerZone, EncounterGrowthRate, BossGrowthRate, IsEnabled | ★★ |
| **Stages** | StageWorldSettingCatalog | Id, ZonesPerTerritory, IsEnabled | ★ |
| **Stages** | （子表）StageRewardPreviewConfig, StageWorldTerritoryConfig, StageWorldZoneSuffixConfig | 獎勵預覽、世界地圖設定 | ★★ |
| **Dungeons** | DungeonCatalog | Id, DungeonKey, DisplayName, RewardType, DailyTicketLimit, DailyAdTicketLimit, BaseHp/Atk/Def, DifficultyMultiplier, CatFoodPerLevel, SpecialCatFoodPerLevel, DiamondsPerLevel, TrapCageDivisor, WhiskerShardDivisor, IsEnabled, ImagePath, SortOrder | ★★★ |

### 分類 C：競技場相關

| Section | Entity | 主要欄位 | 複雜度 |
|---------|--------|----------|--------|
| **Arena** | ArenaSettingCatalog | Id, DailyFreeTickets, MaxDailyPurchases, TicketsPerPurchase, IsEnabled | ★ |
| **Arena** | ArenaRankCatalog | Id, RankKey, DisplayName, ScoreMin, ScoreMax, SortOrder, IsEnabled, ImagePath | ★★ |
| **Arena** | ArenaBotCatalog | Id, BotKey, DisplayName, ScoreOffset, SortOrder, IsEnabled | ★★ |
| **Arena** | （子表）ArenaTicketPurchaseCostConfig, ArenaBotMemberConfig | 購票費用、機器人成員 | ★★ |

### 分類 D：抽卡相關

| Section | Entity | 主要欄位 | 複雜度 |
|---------|--------|----------|--------|
| **Gacha** | GachaSettingCatalog | Id, DailyFreePullCap, DuplicateCatShardReward, TrapPointsExtraPullCost, TrapPointsCatShardCost, IsEnabled | ★ |
| **Gacha** | GachaPullOptionCatalog | Id, PullCount, DiamondCost, RequiredTrapCages, SortOrder, IsEnabled | ★★ |
| **Gacha** | GachaTechniqueLevelCatalog | Id, TechniqueLevel, RequiredPullCount, IsEnabled | ★★ |
| **Gacha** | GachaRarityPresentationCatalog | Id, RarityType, RarityKey, DisplayName, ColorHex, SortOrder, IsEnabled | ★★ |
| **Gacha** | （子表）GachaTechniqueRateConfig | 各等級各稀有度抽中率 | ★★★ |

### 分類 E：Scooper 閒置系統

| Section | Entity | 主要欄位 | 複雜度 |
|---------|--------|----------|--------|
| **Scooper** | ScooperIdleSettingCatalog | Id, MaxIdleHours, ScoopExpChance, ScoopExpAmount, ScoopMemoryShardBaseChance, ScoopWhiskerBaseChance, ScoopWhiskerChancePerScooperLevel, ScoopMemoryShardChancePerTwoScooperLevels, ScooperExpPerLevel, IsEnabled | ★★ |
| **Scooper** | ScooperEquipmentCatalog | Id, DisplayName, UnlockLevel, BasePurchaseCost, BreakChance, SickChance, BaseRepairCost, BaseTreatCost, IsEnabled | ★★ |
| **Scooper** | ScooperSpecialAbilityCatalog | Id, DisplayName, Description, EffectType, EffectValue, CategoryType, SortOrder, IsEnabled, SourceText, DuplicateCompensationDiamonds | ★★ |
| **Scooper** | （子表）ScooperIdleBaseRateConfig, ScooperIdleStageBonusConfig, ScooperIdleScooperBonusConfig, ScooperEquipmentEffectConfig, ScooperEquipmentExpRollConfig | 掉率、加成、裝備效果 | ★★★ |

### 分類 F：物品／道具相關

| Section | Entity | 主要欄位 | 複雜度 |
|---------|--------|----------|--------|
| **Core** | CurrencyCatalog | Id, DisplayName, SortOrder, IsEnabled, ImagePath, Description | ★ |
| **Core** | ConsumableCatalog | Id, DisplayName, ItemCategoryType, MaxStack, IsEnabled, ImagePath, Description, SortOrder | ★ |
| **Memories** | MemoryCatalog | Id, DisplayName, Description, ImagePath, PlaceholderColor, SortOrder, UnlockCost, BonusStatType, BonusValue, IsEnabled | ★★ |
| **Treasures** | TreasureCatalog | Id, DisplayName, Description, SourceText, ImagePath, PlaceholderColor, SortOrder, IsEnabled | ★★ |
| **Treasures** | （子表）TreasureEffectConfig | 效果類型與數值 | ★ |

### 分類 G：成就／商店相關

| Section | Entity | 主要欄位 | 複雜度 |
|---------|--------|----------|--------|
| **Achievements** | AchievementCatalog | Id, DisplayName, CategoryType, SortOrder, IsEnabled, ConditionType, ConditionValue | ★★ |
| **Achievements** | （子表）AchievementRewardConfig | 獎勵內容 | ★ |
| **Shop** | ShopBundleGroupCatalog | Id, CategoryType, GroupType, DisplayName, SortOrder, IsEnabled | ★ |
| **Shop** | ShopBundleCatalog | Id, DisplayName, Description, CategoryType, GroupType, PriceCurrencyId, PriceAmount, DiscountPercent, PurchaseLimit, SortOrder, IsEnabled | ★★ |
| **Shop** | （子表）ShopBundleRewardConfig | 商品內含物品與數量 | ★ |

---

## 三、複雜度說明

| 複雜度 | 說明 |
|--------|------|
| ★ | 單一扁平表，欄位少且皆為基礎型別（string/int/bool） |
| ★★ | 欄位稍多，或含 Enum 下拉選單、SortOrder 排序 |
| ★★★ | 含子表（一對多關聯），或數值較多需要數字驗證 |

---

## 四、目前缺少的功能（JSON 編輯器痛點）

1. **無欄位型別提示** — bool 填成 0/1 或 "true" 字串都可能出錯
2. **無 Enum 下拉** — CatType、RarityType、ItemCategoryType 等需記憶常數
3. **無 SortOrder 拖拉排序** — 只能手動改數字
4. **無圖片預覽** — ImagePath 無法確認圖檔是否存在
5. **無子表 UI** — SkillEffectConfig、GachaTechniqueRateConfig 等子表在 JSON 中很難維護
6. **無搜尋 / 篩選** — 貓咪數量多時難以快速找到目標
7. **無 IsEnabled 快速切換** — 需進 JSON 內找欄位修改

---

## 五、建議開發優先順序

依照「改版效益高」×「開發難度低」排序：

| 優先 | Section | 狀態 | 理由 |
|------|---------|------|------|
| P1 | **Core**（Currency / Consumable） | ✅ 已完成 | 欄位最少最簡單，適合作為 UI 框架的 MVP |
| P1 | **Gacha**（全部） | ✅ 已完成 | 設定表 + 抽卡選項 + 技巧等級（含 Rates 子表）+ 稀有度展示 |
| P2 | **Arena**（全部） | ✅ 已完成 | 有子表但不複雜，排名清單 + 機器人清單是標準表格 |
| P2 | **Memories** | ✅ 已完成 | 扁平表，有 PlaceholderColor 可加色票選擇器 |
| P2 | **Treasures** | ✅ 已完成 | 結構與 Memories 類似，子表只有效果 |
| P3 | **Dungeons** | ✅ 已完成 | 數值多，但全是數字 input，無複雜子表 |
| P3 | **Achievements** | ✅ 已完成 | Enum 多，子表簡單（獎勵清單） |
| P3 | **Shop** | ✅ 已完成 | 兩層結構（Group → Bundle），需 parent-child UI |
| P4 | **Cats** | ✅ 已完成 | 欄位最多 + 子表（技能配置），留到 UI 框架穩定後 |
| P4 | **Skills** | ✅ 已完成 | 子表 SkillEffect 有多種效果類型，需動態表單 |
| P4 | **Scooper** | ✅ 已完成 | 子表最複雜，掉率設定需特殊 UI |
| P4 | **Stages** | ✅ 已完成 | 世界設定有多層結構，留最後 |

### P1 完成紀錄（2026-04-19）

**Branch:** `feature/admin-catalog-p1-ui`（MeowPartyDashClient）
**PR:** [#159](https://github.com/ChiangDean/MeowPartyDashClient/pull/159)

**新增檔案：**
- `scripts/configs/AdminCatalogFormHelpers.gd` — 共用表格/表單元件工廠
- `scripts/configs/AdminCatalogCoreRenderer.gd` — Core section（貨幣 + 消耗品表格）
- `scripts/configs/AdminCatalogGachaRenderer.gd` — Gacha section（4 個 Tab：設定表單 + 抽卡選項 + 技巧等級 + 稀有度展示）

**修改檔案：**
- `scripts/configs/AdminCatalogScene.gd` — 加入 renderer factory，core/gacha 自動切換表格 UI，其他 section 保留 JSON fallback

**後端：** 無需修改（所有 DTO 已完備，enum 以字串序列化）

---

### P2 完成紀錄（2026-04-19）

**Branch:** `feature/admin-catalog-p2-ui`（MeowPartyDashClient）
**PR:** [#161](https://github.com/ChiangDean/MeowPartyDashClient/pull/161)

**新增檔案：**
- `scripts/configs/AdminCatalogArenaRenderer.gd` — Arena section（3 Tab：Setting 表單 + Ranks 表格 + Bots 區塊含 Members 子表）
- `scripts/configs/AdminCatalogMemoriesRenderer.gd` — Memories section（扁平表格，含 BonusStatType 下拉）
- `scripts/configs/AdminCatalogTreasuresRenderer.gd` — Treasures section（Treasure 區塊 + TreasureEffect 子表）

**修改檔案：**
- `scripts/configs/AdminCatalogFormHelpers.gd` — 新增 STAT_TYPE、VALUE_MODE、TARGET_SCOPE 等 Enum 選項
- `scripts/configs/AdminCatalogScene.gd` — `_create_renderer()` 加入 arena / memories / treasures

---

### P3/P4 完成紀錄（2026-04-19）

**Branch:** `feature/admin-catalog-p3-ui`（MeowPartyDashClient）
**PR:** [#163](https://github.com/ChiangDean/MeowPartyDashClient/pull/163)

**新增檔案：**
- `scripts/configs/AdminCatalogDungeonsRenderer.gd` — Dungeons section（3 行區塊：基本資訊 + 11 數值欄位 + 圖片描述）
- `scripts/configs/AdminCatalogAchievementsRenderer.gd` — Achievements section（成就區塊 + 獎勵子表）
- `scripts/configs/AdminCatalogShopRenderer.gd` — Shop section（3 Tab：Categories / Groups / Bundles 含獎勵子表）
- `scripts/configs/AdminCatalogStagesRenderer.gd` — Stages section（2 Tab：StageSetting + WorldSetting 含多層子表）
- `scripts/configs/AdminCatalogScooperRenderer.gd` — Scooper section（3 Tab：IdleSetting + Equipment 區塊 + Abilities 表格）
- `scripts/configs/AdminCatalogCatsRenderer.gd` — Cats section（3 行貓咪區塊 + PassiveSkills / ActiveSkills 子表）
- `scripts/configs/AdminCatalogSkillsRenderer.gd` — Skills section（技能區塊 + Effects 子表 + RankScaling 子表）

**修改檔案：**
- `scripts/configs/AdminCatalogFormHelpers.gd` — 補齊全部 Enum 選項陣列（共 14 組）
- `scripts/configs/AdminCatalogScene.gd` — `_create_renderer()` 涵蓋全部 12 個 section

**後端：** 無需修改

---

## 六、建議 UI 元件清單

改版時需要的共用元件：

- `CatalogTable` — 可排序、可篩選的主清單表格
- `CatalogFormModal` — 新增 / 編輯單筆資料的 Modal 表單
- `EnumDropdown` — 從後端 Enum 清單動態生成下拉選單
- `SubTableEditor` — 一對多子表的嵌入式清單編輯器（用於技能效果、商品內容等）
- `ColorPickerField` — 針對 ColorHex / PlaceholderColor 欄位
- `ImagePathField` — 顯示 ImagePath 並嘗試預覽對應圖檔
- `SortOrderDragList` — 拖拉調整 SortOrder 的清單

---

## 七、後端現況確認

- 所有 22 個實體均已有對應的 `EntityConfigure` 與資料庫 Migration
- `AdminCatalogController` 已支援全部 12 個 Section 的 Get/Save
- `AdminCatalogContracts.cs`（608 行）定義完整 DTO，前端改版無需後端變更
- 資料快取透過 `StaticCatalogCacheKeys`（23 個常數）管理，Save 後自動失效

**結論：UI 改版完全是前端工作，後端無需任何修改。**
