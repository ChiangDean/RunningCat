# Red Dot System Frontend

> Draft date: 2026-04-20
> Audience: PM, frontend engineers, UI engineers
> Scope: planned frontend red-dot behavior for home entry buttons, secondary tabs, and feature-local actionable states

This document defines the frontend red-dot rules for MeowPartyDash. The goal is to make every red dot represent one clear meaning:

- there is something claimable
- there is something free
- there is something pending that the player can process
- there is something unlockable or upgradeable right now

This file is a planned frontend GDD and should be treated as the source of truth for future implementation. It does not assume every condition is already implemented in the current client build.

---

## 1. UX Goal

Red dots should help the player find immediate actions with value. They should not be used for passive information or low-priority reminders.

Priority order:

1. Claimable reward
2. Free action
3. Pending application or unread item
4. Resource-sufficient unlock or upgrade

If multiple child conditions are true inside one feature, the entry still shows one red dot only.

---

## 2. Visual Rule

Current frontend should use the shared helper:

- `scripts/ui/badge_overlay.gd`
- `BadgeOverlay.add_dot(target)`
- `BadgeOverlay.remove(target)`

Current scope uses dot badges only:

- use red dot for boolean state
- do not show numeric counts in this phase
- keep one dot per button or tab
- place the dot at the top-right corner of the clickable control

Recommended behavior:

- entry button red dot: aggregate child states
- feature tab red dot: aggregate local sub-states
- page action button red dot: only for the exact actionable CTA

---

## 3. Aggregation Rule

The frontend should evaluate red-dot state in three layers.

### 3.1 Layer A: Action-Level Red Dot

This is the smallest actionable condition.

Examples:

- party free cheer available
- friend incoming request exists
- mail claimable attachment exists
- achievement reward can be claimed

### 3.2 Layer B: Feature-Level Red Dot

Feature-level red dot is `true` when any action-level red dot inside that feature is `true`.

Examples:

- `party_red_dot = party_free_cheer_available OR party_review_pending`
- `friend_red_dot = friend_send_all_gift_available OR friend_request_pending`

### 3.3 Layer C: Home Entry Red Dot

Home-entry red dot is `true` when the feature itself or any child route under that entry is `true`.

Examples:

- `activity_red_dot = dungeon_red_dot OR arena_red_dot`
- `shop_red_dot = shop_free_bundle_claimable OR trap_free_attempt_available`
- `scooper_red_dot = scooper_achievement_claimable OR scooper_memory_unlockable OR scooper_equipment_unlockable`

---

## 4. Refresh Timing

Red-dot state should refresh at these moments:

1. after bootstrap payload is applied
2. when returning to the home shell
3. when opening a related feature scene
4. after any action that may consume or clear the condition
5. after any API refresh that updates mail, party, friend, arena, dungeon, shop, gacha, or scooper data

Recommended frontend rule:

- consume action success -> update local feature state immediately -> recompute parent red dots
- do not wait for a full app restart to clear a used red dot

---

## 5. B. Program Judgment Conditions

This section defines the boolean conditions the frontend should evaluate.

### 5.1 Party

Feature key:

- `party_red_dot`

Action keys:

- `party_free_cheer_available`
- `party_review_pending`

Conditions:

- `party_free_cheer_available = party.in_party AND party.cheer.free_remaining_count > 0`
- `party_review_pending = party.role == "leader" AND party.pending_application_count > 0`

Feature aggregation:

- `party_red_dot = party_free_cheer_available OR party_review_pending`

Notes:

- Free ad-cheer should not use the same red dot unless PM later decides that ad-based actions also count as urgent.
- Outgoing invites are tracking data only and should not create a red dot.

### 5.1A Scooper Idle Coupon

Feature key:

- `scooper_idle_coupon_red_dot`

Action keys:

- `scooper_idle_coupon_available`
- `scooper_idle_claim_reward_available`

Conditions:

- `scooper_idle_coupon_available = partyCheerCouponCount > 0`
- `scooper_idle_claim_reward_available = idleElapsedSeconds >= 14400`

Feature aggregation:

- `scooper_idle_coupon_red_dot = scooper_idle_coupon_available OR scooper_idle_claim_reward_available`

Notes:

- This red dot belongs to the home idle-reward shortcut, not the party page.
- The same condition should be applied to both the outer `清理貓砂盆 HH:MM:SS` button and the inner `使用收益券(...)` CTA inside the idle dialog.
- Consuming a coupon should clear the red dot immediately after `walletSnapshot` updates the local count to `0`.
- When idle rewards have accumulated for `4` hours or longer, the outer `清理貓砂盆 HH:MM:SS` button should also light, even if the player has no coupon.
- The idle dialog `領取獎勵` CTA should light only from the `idleElapsedSeconds >= 14400` rule.

### 5.2 Friend

Feature key:

- `friend_red_dot`

Action keys:

- `friend_send_all_gift_available`
- `friend_request_pending`

Conditions:

- `friend_send_all_gift_available = friend.ungifted_friend_count > 0`
- `friend_request_pending = friend.incoming_request_count > 0`

Feature aggregation:

- `friend_red_dot = friend_send_all_gift_available OR friend_request_pending`

### 5.3 Mail

Feature key:

- `mail_red_dot`

Action keys:

- `mail_has_unread`
- `mail_has_claimable_attachment`

Conditions:

- `mail_has_unread = mail.unread_count > 0`
- `mail_has_claimable_attachment = mail.claimable_count > 0`

Feature aggregation:

- `mail_red_dot = mail_has_unread OR mail_has_claimable_attachment`

Rule:

- mail entry red dot should light if either unread mail exists or any attachment can be claimed

### 5.4 Scooper

Feature key:

- `scooper_red_dot`

Action keys:

- `scooper_achievement_claimable`
- `scooper_memory_unlockable`
- `scooper_equipment_unlockable`

Conditions:

- `scooper_achievement_claimable = scooper.claimable_achievement_count > 0`
- `scooper_memory_unlockable = EXISTS locked_memory WHERE scooper.memory_shards >= locked_memory.unlock_cost`
- `scooper_equipment_unlockable = EXISTS locked_equipment WHERE scooper.level >= locked_equipment.unlock_level AND player.gold >= locked_equipment.unlock_gold_cost`

Feature aggregation:

- `scooper_red_dot = scooper_achievement_claimable OR scooper_memory_unlockable OR scooper_equipment_unlockable`

Rule:

- if multiple scooper tabs are actionable at the same time, the root scooper entry still shows one dot only

### 5.5 Dungeon

Feature key:

- `dungeon_red_dot`

Action keys:

- `dungeon_ticket_available`

Conditions:

- `dungeon_ticket_available = dungeon.ticket_count > 0`

Feature aggregation:

- `dungeon_red_dot = dungeon_ticket_available`

Optional future extension:

- if dungeon later adds claimable daily reward or free reset, those can join the same aggregation

### 5.6 Cat Enhancement

Feature key:

- `enhance_red_dot`

Action keys:

- `cat_rank_up_available`

Conditions:

- `cat_rank_up_available = EXISTS owned_cat WHERE owned_cat.can_rank_up == true`

Feature aggregation:

- `enhance_red_dot = cat_rank_up_available`

Recommended backend or frontend adapter rule:

- `can_rank_up` should already include material, currency, and unlock-stage checks so the UI does not recompute complex formulas in multiple places

### 5.7 Trap Or Gacha

Feature key:

- `trap_red_dot`

Action keys:

- `trap_free_attempt_available`

Conditions:

- `trap_free_attempt_available = gacha.free_attempt_count > 0`

Feature aggregation:

- `trap_red_dot = trap_free_attempt_available`

Rule:

- if the shop entry is the actual home entry for this feature, `trap_red_dot` should roll up into `shop_red_dot`

### 5.8 Arena

Feature key:

- `arena_red_dot`

Action keys:

- `arena_reward_claimable`

Conditions:

- `arena_reward_claimable = arena.claimable_reward_count > 0`

Feature aggregation:

- `arena_red_dot = arena_reward_claimable`

### 5.9 Shop

Feature key:

- `shop_red_dot`

Action keys:

- `shop_free_bundle_claimable`
- `trap_free_attempt_available`

Conditions:

- `shop_free_bundle_claimable = shop.free_bundle_count > 0`
- `trap_free_attempt_available = gacha.free_attempt_count > 0`

Feature aggregation:

- `shop_red_dot = shop_free_bundle_claimable OR trap_free_attempt_available`

### 5.10 Activity Aggregate

Feature key:

- `activity_red_dot`

Conditions:

- `activity_red_dot = dungeon_red_dot OR arena_red_dot`

Rule:

- this is a navigation aggregate only
- the Activity entry should not invent its own new business condition

---

## 6. C. UI Red-Dot Node Map

This section defines where the frontend should place the red dots.

The table uses recommended node keys. Exact runtime control names may differ in implementation, but the red-dot ownership should follow this structure.

| Feature | Scene / page | UI target | Recommended node key | Red-dot source |
| --- | --- | --- | --- | --- |
| Party | Home HUD entry | Party entry button on home HUD | `home_entry_party_button` | `party_red_dot` |
| Party | `PartyScene` main section | Cheer action button | `party_cheer_button` | `party_free_cheer_available` |
| Party | `PartyScene` bottom submenu | Review tab button | `party_review_tab_button` | `party_review_pending` |
| Friend | Home HUD entry | Friend entry button on home HUD | `home_entry_friend_button` | `friend_red_dot` |
| Friend | `FriendScene` friend list section | Send-all-gift button | `friend_send_all_gift_button` | `friend_send_all_gift_available` |
| Friend | `FriendScene` bottom submenu | Incoming request tab button | `friend_request_inbox_tab_button` | `friend_request_pending` |
| Mail | Home HUD entry | Mail entry button on home HUD | `home_entry_mail_button` | `mail_red_dot` |
| Mail | `MailOverlayScene` or `MailScene` | Unread tab button | `mail_unread_tab_button` | `mail_has_unread` |
| Mail | `MailScene` top action row | Claim-all button | `mail_claim_all_button` | `mail_has_claimable_attachment` |
| Scooper | Home bottom nav | Scooper entry button | `home_entry_scooper_button` | `scooper_red_dot` |
| Scooper | Home HUD idle shortcut | `清理貓砂盆 HH:MM:SS` button | `home_idle_claim_button` | `scooper_idle_coupon_red_dot` |
| Scooper | Idle reward dialog | `使用收益券(...)` button | `home_idle_coupon_button` | `scooper_idle_coupon_available` |
| Scooper | Idle reward dialog | `領取獎勵` button | `home_idle_claim_rewards_button` | `scooper_idle_claim_reward_available` |
| Scooper | `ScooperScene` tab row | Achievement tab button | `scooper_tab_achievement_button` | `scooper_achievement_claimable` |
| Scooper | `ScooperScene` tab row | Memory tab button | `scooper_tab_memory_button` | `scooper_memory_unlockable` |
| Scooper | `ScooperScene` tab row | Equipment or treasure-related tab button | `scooper_tab_equipment_button` | `scooper_equipment_unlockable` |
| Activity | Home bottom nav | Activity entry button | `home_entry_activity_button` | `activity_red_dot` |
| Activity | `ActivityScene` submenu | Dungeon tab button | `activity_dungeon_tab_button` | `dungeon_red_dot` |
| Activity | `ActivityScene` submenu | Arena tab button | `activity_arena_tab_button` | `arena_red_dot` |
| Dungeon | `DungeonScene` | Main challenge button or ticket area | `dungeon_ticket_cta` | `dungeon_ticket_available` |
| Arena | `ArenaScene` | Reward claim button or reward chest button | `arena_reward_button` | `arena_reward_claimable` |
| Enhance | Home bottom nav or feature entry | Enhance entry button | `home_entry_enhance_button` | `enhance_red_dot` |
| Enhance | `EnhanceScene` | Rank-up related CTA | `enhance_rank_up_cta` | `cat_rank_up_available` |
| Shop | Home bottom nav | Shop entry button | `home_entry_shop_button` | `shop_red_dot` |
| Shop | `ShopScene` bundle section | Free bundle card or CTA | `shop_free_bundle_cta` | `shop_free_bundle_claimable` |
| Shop / Trap | `ShopScene` or `GachaScene` | Free trap / free gacha CTA | `shop_free_trap_cta` | `trap_free_attempt_available` |

---

## 7. Home Entry Ownership

Recommended ownership in the current frontend architecture:

- home-level red-dot aggregation should be coordinated from the persistent home shell flow
- `BattleScene` or the home HUD builder should only render the current aggregate result
- feature pages should own their own local recomputation and then notify the parent aggregate

Recommended state shape:

```text
red_dot_state = {
  party: bool,
  friend: bool,
  mail: bool,
  scooper: bool,
  dungeon: bool,
  arena: bool,
  activity: bool,
  enhance: bool,
  trap: bool,
  shop: bool
}
```

Recommended ownership split:

- feature scene computes child conditions
- shared home state stores aggregate booleans
- shared badge helper applies or removes the dot on concrete controls

---

## 8. Data Contract Recommendation

To avoid duplicated business rules across scenes, the frontend should prefer summary fields from bootstrap or overview APIs instead of recalculating every condition from raw lists.

Recommended summary fields:

- `party.pending_application_count`
- `party.cheer.free_remaining_count`
- `friend.incoming_request_count`
- `friend.ungifted_friend_count`
- `mail.unread_count`
- `mail.claimable_count`
- `scooper.claimable_achievement_count`
- `scooper.memory_unlockable_count`
- `scooper.equipment_unlockable_count`
- `dungeon.ticket_count`
- `arena.claimable_reward_count`
- `shop.free_bundle_count`
- `gacha.free_attempt_count`
- `enhance.rank_up_available_count`

If the backend can provide these counts directly, frontend complexity and inconsistency risk will be much lower.

---

## 9. Non-Goals

This phase does not define:

- numeric badge counts
- animation rules for red-dot pulsing
- server push or websocket refresh for red dots
- low-priority reminder dots for lore, previews, or informational notices

---

## 10. Delivery Summary

Current planned red-dot feature list:

1. Party free cheer
2. Party pending applications for leader review
3. Friend one-key gift
4. Friend incoming requests
5. Mail unread
6. Mail claimable attachments
7. Scooper achievement claim
8. Scooper memory unlock
9. Scooper equipment unlock
10. Dungeon ticket available
11. Cat rank-up available
12. Free trap or gacha attempt
13. Arena reward claim
14. Shop free bundle claim

If future systems need red dots, they should follow the same pattern:

- define action-level conditions first
- aggregate into feature-level state
- then map the state to concrete UI nodes
