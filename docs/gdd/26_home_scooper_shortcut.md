# 26. 首頁鏟屎快捷入口與自動鏟屎

> 最後更新：2026-04-18

本文件補充主畫面 `BattleScene` 上的首頁鏟屎快捷入口規格，包含鏟屎主按鈕、右側自動鏟屎開關、動畫與資料流。

---

## 1. UI 結構

- 首頁鏟屎快捷入口由 `scenes/ui/HomeScoopButtonTemplate.tscn` 提供模板。
- `scripts/battle/battle_scene.gd` 在主畫面載入此模板，並定位在主選單上方。
- 模板內目前包含：
  - `ScoopButton`：鏟屎主按鈕，使用 14 張 frame 的 sprite sheet 動畫
  - `CountLabel`：顯示目前剩餘屎堆數量
  - `ResultLabel`：保留錯誤或局部提示文字
  - `AutoScoopToggleButton`：右側自動鏟屎開關

## 2. 單次鏟屎流程

1. 玩家按下 `ScoopButton`
2. Client 立即送出 `POST /api/scooper/profile/scoop`
3. 同步開始播放鏟屎動畫，期間按鈕鎖定
4. 等動畫結束後才套用本次結算
5. 將 `updatedProfile` 或補抓回來的 profile 寫回 `GameState.update_scooper_profile(...)`
6. 使用主畫面共用的 reward float 顯示 EXP / 回憶碎片 / 鬍鬚獎勵

補充：

- 首頁鏟屎目前使用 `ApiClient.scoop_poop_silent(count)`，不顯示全域 loading 遮罩。
- 冷卻時間與動畫時間目前同步為 `2` 秒。

## 3. 自動鏟屎開關

### 3-1. 視覺狀態

- 開關使用兩張獨立圖片：
  - `auto_scoop_toggle_off.svg`
  - `auto_scoop_toggle_on.svg`
- 點擊後直接切換圖片，不開啟額外 Dialog。

### 3-2. 行為規則

- 玩家開啟自動鏟屎後，主畫面每隔 `2` 秒觸發一次鏟屎。
- 本期規格先固定每次呼叫 `scoop(1)`。
- 當以下任一條件成立時，自動鏟屎會停止：
  - `poopCount <= 0`
  - 玩家手動關閉開關
  - API 請求失敗

### 3-3. 與單次鏟屎共用規則

- 自動鏟屎沿用與手動鏟屎相同的動畫、冷卻、API 與獎勵顯示流程。
- 自動鏟屎不建立新的後端 API，也不建立新的本地持久化資料檔。

## 4. 資料流與狀態歸屬

### 4-1. Scene-local state

以下狀態屬於 `BattleScene`，不寫入 `GameState`：

- 自動鏟屎是否開啟
- 鏟屎動畫是否播放中
- 鏟屎冷卻剩餘時間
- 鏟屎 request in flight
- 等待動畫結束後才結算的暫存 reward / profile

### 4-2. Global state

以下資料仍由 `GameState` 與 `user://player_data/scooper/profile.json` 持有：

- `scooperLevel`
- `scooperExp`
- `poopCount`
- `memoryShards`
- `whiskers`

## 5. 後續擴充預留

- 設計上曾提到「鏟屎官等級 / 特殊能力可能影響單次可鏟數量」。
- 目前 client 與 API 尚未有穩定欄位可直接表示此值，因此本期不在前端硬編規則。
- `BattleScene` 已保留單次鏟屎數量 hook；未來若後端提供例如：
  - `autoScoopBatchSize`
  - `maxScoopCountPerAction`
  - 其他等價欄位
  則首頁自動鏟屎應直接改由後端欄位決定單次 `count`。

原則：

- 真正的單次最大鏟屎數量應由後端或後端同步到 client 的權威資料決定。
- 前端只負責讀取、顯示與定時觸發，不自行推導最終規則。
