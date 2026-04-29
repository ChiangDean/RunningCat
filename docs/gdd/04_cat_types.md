# 四、貓咪種類

## 職業定義

共 5 種，對應 `CatTypeEnum`（詳見後端 `enums.md`）。站位決定攻擊對象與受擊優先度。

| 職業 | 中文 | 站位 | 定位 | 核心屬性 |
|------|------|------|------|---------|
| `tank` | 重裝 | 前排 | 扛傷吸引火力 | 高 HP、高 DEF、高 Weight |
| `crusader` | 聖戰 | 前排 | 前排輸出兼增益 | 均衡 ATK/DEF，含 Buff 技 |
| `assassin` | 暗殺 | 中排 | 攻擊後排/最低 HP 目標 | 高 ATK、高 Speed、高 CritRate |
| `striker` | 突襲 | 中排 | 衝擊前排、全體連擊 | 高 Speed、高 MultiHitRate |
| `support` | 輔助 | 後排 | 治癒 / 復活 / 縮 CD | 高 HP、輔助技能 |

## 角色列表

> 稀有度：N=普通 R=優良 SR=稀有 SSR=超稀有 SP=特別  
> 獲取方式：誘捕籠（Gacha）

| 貓咪 | cat_key | 職業 | 稀有度 |
|------|---------|------|--------|
| 乳牛貓 | `cow_cat` | Tank | N |
| 大橘貓 | `orange_cat` | Tank | N |
| 賓士貓 | `tuxedo_cat` | Crusader | N |
| 虎斑貓 | `tabby_cat` | Crusader | N |
| 黑貓 | `black_cat` | Assassin | N |
| 煙燻貓 | `smoke_cat` | Assassin | N |
| 三花貓 | `calico_cat` | Striker | N |
| 玳瑁貓 | `tortoiseshell_cat` | Striker | N |
| 白貓 | `white_cat` | Support | N |
| 奶油貓 | `cream_cat` | Support | N |
| 牛奶貓 | `milk_cat` | Tank | R |
| 英短貓 | `british_shorthair_cat` | Crusader | R |
| 暹羅貓 | `siamese_cat` | Assassin | R |
| 美短貓 | `american_shorthair_cat` | Striker | R |
| 銀貓 | `silver_cat` | Support | R |
| 摺耳貓 | `scottish_fold_cat` | Tank | SR |
| 波斯貓 | `persian_cat` | Crusader | SR |
| 俄羅斯藍貓 | `russian_blue_cat` | Assassin | SR |
| 阿比西尼亞貓 | `abyssinian_cat` | Striker | SR |
| 布偶貓 | `ragdoll_cat` | Support | SR |
| 緬因貓 | `maine_coon_cat` | Tank | SSR |
| 挪威森林貓 | `norwegian_forest_cat` | Crusader | SSR |
| 無毛貓 | `sphinx_cat` | Assassin | SSR |
| 孟加拉貓 | `bengal_cat` | Striker | SSR |
| 曼赤肯貓 | `munchkin_cat` | Support | SSR |
| 忍者貓 | `ninja_cat` | Assassin | SP |
