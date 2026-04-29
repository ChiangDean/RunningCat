# 31. 關卡通關獎勵系統（前端）

> Last updated: 2026-04-29

對應後端 API：`POST /api/scooper/profile/stage-clear`

---

## 1. 目標

玩家首次通關某關卡時，自動向後端申報並接收獎勵。整個流程在背景靜默完成，不打斷戰鬥節奏。

---

## 2. 觸發時機與流程

```
advance_after_win()
  └── 記錄 _stage_clear_pending_stage / _stage_clear_pending_boss
  └── 版本號 ++ (_stage_clear_debounce_version)
  └── 啟動 10 秒 Timer

Timer 到期 → _flush_stage_clear_reward(version)
  └── 若 version ≠ _stage_clear_debounce_version → 放棄（中途有更新通關）
  └── 否則 → ApiClient.stage_clear_silent(stage, is_boss, callback)

_on_stage_clear_reward(ok, data, err)
  └── ok=false → 靜默忽略（不影響遊戲）
  └── ok=true  → 套用 data.wallet_snapshot 到本地狀態
```

### 防抖說明

- 玩家快速連過多關時，Timer 每次通關都會重設。
- 10 秒內無新通關 → 只呼叫一次 API，以**最後一關**為準。
- 確保不因快速推關而發出大量 API 請求。

---

## 3. 獎勵數值（由後端計算，客戶端僅展示）

### 普通關（territory = floor((clearedStage - 1) / 50) + 1）

| 獎勵項目 | 公式 | 說明 |
|---------|------|------|
| 金幣 | `15 + (t-1) × 5` | t = territory |
| 鑽石 | `1` | 固定 |
| 便便 | `t` | |

### 首領關（每 10 關 Boss）

| 獎勵項目 | 公式 | 說明 |
|---------|------|------|
| 金幣 | `25 + (t-1) × 10` | t = territory |
| 鑽石 | `2` | 固定 |
| 特殊貓糧 | `1` | 固定 |
| 便便 | `1 + t × 2` | |

> **注意：僅首次通關發獎**，已推過的關卡重複過不再給予。

---

## 4. API 請求與回應

### 請求（`StageClearRequest`）

```json
{
  "clearedStage": 10,
  "isBoss": true
}
```

### 回應（`StageClearResponse`）

```json
{
  "rewardsGranted": true,
  "gold": 25,
  "diamonds": 2,
  "poopCount": 3,
  "specialCatFood": 1,
  "walletSnapshot": {
    "gold": 12345,
    "diamonds": 88,
    ...
  }
}
```

- `rewardsGranted = false`：已通關過，本次不發獎（客戶端靜默處理）。

---

## 5. 客戶端實作位置

| 檔案 | 職責 |
|-----|------|
| `scripts/ApiClient.gd` | `stage_clear_silent(stage, is_boss, cb)` — 無 loading overlay 的靜默 POST |
| `scripts/gamestate/GameState.gd` | 防抖邏輯、版本號管理、wallet 套用 |

### GameState.gd 狀態變數

```gdscript
var _stage_clear_debounce_version: int = 0
var _stage_clear_pending_stage: int = -1
var _stage_clear_pending_boss: bool = false
```

---

## 6. 錯誤處理

- API 呼叫失敗（網路問題、伺服器錯誤）→ **靜默忽略**，不影響遊戲進行。
- 下次登入後，後端的 `profile.CurrentStage` 仍為正確狀態（已推過的關不重發）。
- 客戶端 wallet 若因失敗未更新，會在下次 API 回應（如鏟屎、登入）自動同步。

---

## 7. UI 表現

- 本版本：**無彈窗、無動畫**，完全靜默。
- 未來可考慮在通關動畫結束後顯示輕量 toast（金幣 +N、鑽石 +N）。
