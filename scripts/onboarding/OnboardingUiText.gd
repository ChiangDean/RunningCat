class_name OnboardingUiText
extends RefCounted

# ── 步驟進度點 ──
const STEP_DOT_ACTIVE := "●"
const STEP_DOT_INACTIVE := "○"

# ── Step 1：鏟屎官名稱 ──
const NAME_TITLE := "你叫什麼名字？"
const NAME_SUBTITLE := "告訴這個世界你的稱號吧！"
const NAME_PLACEHOLDER := "輸入鏟屎官稱號"
const NAME_CONFIRM := "就這個了！"
const NAME_SKIP := "略過"
const NAME_ERROR_EMPTY := "請輸入名稱，或點擊略過。"
const NAME_HINT := "這個名字會跟著你的貓咪一起出現在世界上。"

# ── Step 2：選貓 ──
const CAT_PICKER_TITLE := "選擇你的第一隻貓"
const CAT_PICKER_SUBTITLE := "牠會成為你的初始夥伴，帶著牠一起探索吧！"
const CAT_PICKER_CONFIRM := "領養牠！"
const CAT_PICKER_HINT := "點選一隻貓來查看詳情"
const CAT_PICKER_SELECTED_FORMAT := "你選擇了「%s」"
const CAT_PICKER_LOADING := "正在安排領養手續..."
const CAT_PICKER_ERROR := "領養失敗，請再試一次。"

# ── Step 3：世界觀對話 ──
const DIALOGUE_SKIP := "略過對話"
const DIALOGUE_NEXT := "下一頁"
const DIALOGUE_START := "開始冒險！"

# ── 對話內容（旁白用 speaker = ""，貓咪用 speaker = cat_name，玩家用 speaker = player_name）──
# 格式：[speaker, text, show_cat_image]
# speaker = "" → 旁白（無頭像）
# speaker = "{cat_name}" → 貓咪（顯示貓圖）
# speaker = "{player_name}" → 鏟屎官（無圖）

const DIALOGUE_BEAT_NARRATOR_1_SPEAKER := ""
const DIALOGUE_BEAT_NARRATOR_1_TEXT := "某個平凡的街角，有個人每天都準時出現。\n不論颳風下雨，手上永遠拿著貓罐頭。"

const DIALOGUE_BEAT_NARRATOR_2_SPEAKER := ""
const DIALOGUE_BEAT_NARRATOR_2_TEXT := "這個人就是你——\n在這個以派對解決一切的貓咪世界裡，你是一位鏟屎官。"

const DIALOGUE_BEAT_CAT_1_SPEAKER := "{cat_name}"
const DIALOGUE_BEAT_CAT_1_TEXT := "哼，那個每天來的人類。\n罐頭還行。但想摸我？做夢。"

const DIALOGUE_BEAT_PLAYER_1_SPEAKER := "{player_name}"
const DIALOGUE_BEAT_PLAYER_1_TEXT := "……我一定要把牠帶回家。"

const DIALOGUE_BEAT_NARRATOR_3_SPEAKER := ""
const DIALOGUE_BEAT_NARRATOR_3_TEXT := "你帶來了一個特殊的道具——誘捕籠。\n裡面放了最高級的鮪魚罐頭。"

const DIALOGUE_BEAT_CAT_2_SPEAKER := "{cat_name}"
const DIALOGUE_BEAT_CAT_2_TEXT := "喔？今天的罐頭擺在一個奇怪的鐵籠子裡。\n不管，先吃再說。\n\n……咔——"

const DIALOGUE_BEAT_PLAYER_2_SPEAKER := "{player_name}"
const DIALOGUE_BEAT_PLAYER_2_TEXT := "我抓到你了！！"

const DIALOGUE_BEAT_CAT_3_SPEAKER := "{cat_name}"
const DIALOGUE_BEAT_CAT_3_TEXT := "這……這不是我的計畫！\n我只是……順便……\n對，我是故意進去的。"

const DIALOGUE_BEAT_NARRATOR_4_SPEAKER := ""
const DIALOGUE_BEAT_NARRATOR_4_TEXT := "主人不在的時候，{cat_name} 非常忙碌。\n撞倒花瓶、把衛生紙拆完、吃飯、上廁所……\n再撞倒一個杯子——只是因為它就在那裡。"

const DIALOGUE_BEAT_CAT_4_SPEAKER := "{cat_name}"
const DIALOGUE_BEAT_CAT_4_TEXT := "破壞慾望：已滿足。\n肚子：飽。廁所：已使用（多次）。\n今天也是美好的一天。"

const DIALOGUE_BEAT_NARRATOR_5_SPEAKER := ""
const DIALOGUE_BEAT_NARRATOR_5_TEXT := "主人回家，展開熟練的鏟屎作業。\n每鏟一次，眼神就更柔和一分。"

const DIALOGUE_BEAT_CAT_5_SPEAKER := "{cat_name}"
const DIALOGUE_BEAT_CAT_5_TEXT := "那些來拜訪的人類……全都是敵人。\n試圖摸我、抱我、把臉湊過來的，\n通通要衝撞驅趕。"

const DIALOGUE_BEAT_NARRATOR_6_SPEAKER := ""
const DIALOGUE_BEAT_NARRATOR_6_TEXT := "{player_name} 的誘捕籠，再次出動了。\n一隻不夠，永遠不夠。\n\n你們的故事，就此展開！"

# ── 結尾 ──
const COMPLETE_TITLE := "歡迎來到喵喵衝撞派對！"
const COMPLETE_SUBTITLE_FORMAT := "%s 與 %s，冒險開始了！"
const COMPLETE_BUTTON := "開始遊戲！"
