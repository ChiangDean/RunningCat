# 十一、技能系統

> 最後更新：2026-04-04

---

## 技能種類

### 被動技能
- 戰鬥**開始即生效**，持續整場戰鬥
- 效果種類：傷害減免、屬性提升（自身或全隊）、全隊冷卻時間縮減

### 主動技能
- 每隔 X 秒**自動發動**（冷卻歸零即觸發）
- **起始施放時間**（0～9 秒）可在配置畫面對每隻貓個別調整
- 硬直期間冷卻繼續計算，硬直結束後才發動
- 效果種類：傷害、Buff（提升自身或全隊屬性，有持續時間）、額外擊退

---

## 技能 JSON 格式

### 主動技能（`data/default/skills/active/*.json`）

```json
{
  "id": "skill_id",
  "display_name": "技能名稱",
  "description": "技能描述",
  "skill_type": "active",
  "cooldown": 5.0,
  "effects": [
    {
      "type": "damage",           // damage | buff_stat | reflect
      "value": 1.30,              // 傷害倍率 或 buff 數值
      "value_type": "percent",    // percent | flat（buff 用）
      "target": "enemy_front",   // enemy_front | enemy_lowest_hp | self | team
      "hits": 1,                  // 連擊次數（damage 用）
      "duration": 4.0,            // 持續時間（buff_stat / reflect 用）
      "stat": "defense",          // 屬性名稱（buff_stat 用）
      "extra_knockback": 50.0     // 額外擊退距離（damage 用，可選）
    }
  ],
  "rank_scaling": [
    {
      "effect_index": 0,          // 對應 effects 陣列的索引
      "property": "value",        // 要加成的屬性（目前只支援 value）
      "per_5_ranks": 0.10         // 每 5 品階增加的量
    }
  ]
}
```

### 被動技能（`data/default/skills/passive/*.json`）

```json
{
  "id": "skill_id",
  "display_name": "技能名稱",
  "description": "技能描述",
  "skill_type": "passive",
  "effects": [
    {
      "type": "stat_boost",       // stat_boost | damage_reduction | cooldown_reduction
      "stat": "atk",              // 屬性名稱（stat_boost 用）
      "value": 0.05,
      "value_type": "percent",
      "target": "self"            // self | team
    }
  ],
  "rank_scaling": [...]
}
```

---

## 支援的效果類型（`type`）

| type | 說明 | 使用場景 |
|------|------|---------|
| `damage` | 對目標造成 `ATK × value` 傷害，可多連擊 | 主動 |
| `buff_stat` | 臨時提升目標屬性（有持續時間，重複施放刷新） | 主動 |
| `reflect` | 施放期間，受到傷害時反彈 `value%` 給攻擊者 | 主動 |
| `stat_boost` | 戰鬥開始永久提升屬性（不倒數） | 被動 |
| `damage_reduction` | 永久減少自身受到的傷害 | 被動 |
| `cooldown_reduction` | 永久縮短全隊冷卻時間 | 被動 |

---

## 品階加成

- 每升 **5 品階**，`rank_scaling` 中對應 `effect_index` 的 `value` 增加 `per_5_ranks`
- 計算公式：`effective_value = base_value + floor(rank / 5) × per_5_ranks`
- 可同時設定多個 `rank_scaling` 條目（對應不同效果）
- 品階加成實際生效於戰鬥模擬器內，UI 顯示於強化畫面「技能」區塊

---

## 各貓咪技能一覽

| 貓咪 | 主動技能 | 效果 | 升階加成（每 5 階）|
|------|----------|------|-----------------|
| 牛奶貓 | 牛奶護盾 | 自身防禦 +30%，持續 4 秒 | 防禦 +5% |
| 大橘貓 | 橫衝直撞 | 130% ATK 攻擊最前排 + 額外擊退 | 傷害 +10% |
| 賓士貓 | 反擊姿態 | 自身防禦 +20%，6 秒內反彈 15% 傷害 | 反彈 +2% |
| 忍者貓 | 影分身斬 | 75% ATK 攻擊血量最低敵人，連擊 2 次 | 每擊 +5% |
| 黑貓   | 黑暗突襲 | 150% ATK 攻擊血量最低敵人 | 傷害 +10% |
| 三花貓 | 幸運衝刺 | 100% ATK 攻擊最前排 + 自身速度 +25%，3 秒 | 傷害 +5%，速度 +3% |

| 貓咪 | 被動技能 | 效果 | 升階加成（每 5 階）|
|------|----------|------|-----------------|
| 牛奶貓 | 厚實體態 | 自身受傷 -8% | -1% |
| 大橘貓 | 大橘威壓 | 我方全體 HP +6% | +1% |
| 賓士貓 | 精英氣場 | 我方全體 ATK +5% | +1% |
| 忍者貓 | 暗殺本能 | 自身 ATK +12% | +2% |
| 黑貓   | 夜行者   | 自身速度 +10% | +1% |
| 三花貓 | 幸運花紋 | 我方全體冷卻 -8% | -1% |

---

## UI 呈現

### 戰鬥畫面（主畫面 / 地下城）
- 戰鬥區下方顯示一排主動技能槽（最多 5 格，對應玩家出戰位置）
- **冷卻中**：灰色遮罩從上往下縮減 + 中央顯示剩餘秒數
- **可發動**：遮罩消失
- **Buff 持續中**：黃色外框顯示技能仍在效果期間

### 配置畫面
- 出戰列表中每隻貓右側有「技能」按鈕
- **長按**（0.4 秒以上）彈出技能資訊面板（主動 + 被動說明、當前品階加成）

### 強化畫面
- 技能名稱右下角顯示品階標示（如 `+3`，金色）
- 「?」按鈕點擊後顯示「目前品階 +N 的技能加成」詳細說明

---

## Buff 規則

- 同一個 Buff 在持續時間內再次觸發 → **刷新持續時間**（不疊加層數）
- 冷卻縮減（CDR）套用至初始延遲與每次冷卻重置

---

## 技能擴充方式

新增技能只需：
1. 在對應目錄新增 JSON 檔案
2. 在貓咪 JSON 的 `passive_skills` / `active_skills` 中填入 id
3. 無需修改程式碼（新效果類型需在模擬器 `_execute_skill` 加一個 match 分支）
