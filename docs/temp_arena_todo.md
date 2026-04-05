# 競技場系統實作清單

> 此為暫存工作日誌，PR 送出後刪除。
> 每完成一項請將 `[ ]` 改為 `[x]`。

---

## 一、資料結構 & 存檔

- [x] 建立 `data/arena/fake_players/` 資料夾，新增 10 個假玩家 JSON（fake_001 ~ fake_010）
- [x] 建立 `data/arena/arena_data.json`（排行榜 Dictionary，key = player_id，value = `{ "score": int }`）
- [x] 建立 `data/default/arena_config.json`（season_end_date、ticket_purchase_costs 等）
- [x] 建立 `scripts/data/player_arena_data.gd`（讀寫 player_arena.json，含每日重置 & 賽季重置）
- [x] 在 `player_data.gd` 新增 `arena_attack_team` & `arena_defense_team` 欄位
- [x] 在 `GameState.gd` 加入 `arena_data`、`arena_opponent`、`arena_config`，啟動時載入並重置

## 二、積分 & 段位邏輯

- [x] 建立 `scripts/systems/arena_rank_system.gd`
  - 總積分 → 段位換算、段位名稱
  - 積分變化計算（依對手段位差、連勝/連敗 ±1）
  - 賽季重置邏輯（比對本機日期 vs season_end_date）
  - 段位獎勵資料（每段位獎勵內容寫死）
  - 段位獎勵領取判斷（已領取清單 + 可領取清單）

## 三、假玩家資料

- [x] `fake_001.json` ～ `fake_010.json`（銅/銀/金牌分布，積分 45~720）
- [x] 假玩家資料直接由 `arena_matchmaking.gd` 讀取，無需獨立 registry

## 四、對手選取系統

- [x] 建立 `scripts/systems/arena_matchmaking.gd`
  - 依積分接近程度篩選（每次擴大 100 分範圍，直到找到足夠候選）
  - 隨機選 3 個，排除本輪已出現過的對手（重骰時傳入 excluded_ids）
  - 重骰冷卻邏輯由 ArenaScene._process 處理（5 秒 grey out + 倒數）

## 五、UI 場景

- [x] 建立 `scenes/ArenaScene.tscn` + `scripts/ArenaScene.gd`（競技場主頁）
  - 顯示玩家名稱、段位、積分、競技券數量
  - 3 個對手卡片（名稱、段位+積分、防守隊伍預覽、挑戰按鈕）
  - 重骰按鈕（grey out + 倒數）
  - 設定防守陣容（popup CheckBox，最多 5 隻）
  - 段位獎勵領取（popup ScrollContainer，可逐筆領取）
  - 購買競技券（ConfirmationDialog，費用遞增）

## 六、戰鬥整合

- [x] 建立 `scenes/ArenaBattleScene.tscn` + `scripts/battle/arena_battle_scene.gd`
  - 上方標題：我方名稱（段位 積分）VS 對方名稱（段位 積分）
  - 敵方使用對手 defense_team 貓咪資料
  - 結果 popup：段位、積分變化（+N/-N）、當前積分，點任意處關閉
  - 戰鬥結束後更新積分、連勝/連敗，save_all()
- [x] 在 `ConfigScene` 新增競技場設定（season_end_date 輸入框 + 購買費用顯示）

## 七、從主畫面進入競技場

- [x] `ActivityScene` 競技場按鈕從「🔒 待開放」改為可點擊，跳轉 ArenaScene

---

## 未來清單（本次不做）

- 信件夾（段位獎勵 & 賽季獎勵發送）
- 多場景隊伍管理介面（BOSS推關 / 地下城 / 競技場攻 / 競技場防）
- 玩家頭像 & 名稱設定（BattleScene 左上角）
- 後端連線（賽季伺服器時間、真實 PvP 對手）
