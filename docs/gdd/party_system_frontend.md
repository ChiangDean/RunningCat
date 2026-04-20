# Party System Frontend

> Update 2026-04-19:
> Party now opens as an overlay scene with the shared bottom submenu.
> The submenu is fixed to `隊伍資訊`、`待回應邀請`、`待審核清單`.
> Invite handling and review handling are now role-aware.

## 1. Entry And Scene Mode

Current entry:
- `battle_scene.gd` opens `res://scenes/PartyScene.tscn`
- no longer uses dialog-style open flow
- initial party detail, cheer status, pending applications, and my applications come from authenticated bootstrap
- websocket `social.party.sync` keeps these datasets current after login and later party membership changes
- entering the party page should not show a visible loading step just to hydrate overview / invite / review data

Wrapper scene:
- `scenes/PartyScene.tscn`
- `scripts/social/PartyScene.gd`

Content controller:
- `scripts/social/SocialScene.gd`

## 2. Bottom Submenu

Shared submenu sections:
- `隊伍資訊`
- `待回應邀請`
- `待審核清單`

The same three sections are always shown for:
- no-party player
- leader
- member

## 3. Section Behavior

### 3.1 隊伍資訊

No-party state:
- inline `建立隊伍`
- inline `申請加入`

In-party state:
- party name
- member list
- rename button
- invite button
- cheer area
- leave / disband / usurp / transfer actions depending on role

`重整` button has been removed from the party page.

### 3.2 待回應邀請

This section is role-aware.

When player has no party:
- shows party invites received by the player
- player can `接受` or `拒絕`
- reject requires second confirmation

When player is already in a party:
- shows outgoing invites sent by this party that are still pending
- list is read-only
- used to track who has not replied yet

### 3.3 待審核清單

This section is also role-aware.

When player has no party:
- shows the player's own pending join applications
- player can cancel their own application

When player is the leader:
- shows join applications to the current party
- leader can `接受` or `拒絕`
- reject requires second confirmation

When player is a normal member:
- shows the same review list as read-only
- cannot confirm or reject

## 4. Invite Flow

Invite is now search-first.

Flow:
1. Press `邀請`.
2. Open invite dialog.
3. Enter target player name.
4. Client calls invite candidate search.
5. Show result list with inertial scroll.
6. Press `邀請` on the chosen row.

Candidate row fields:
- avatar
- player name
- scooper level
- UID
- last login

Search API:
- `GET /api/party/{partyId}/invite-candidates?query=...`

Successful invite:
- dialog closes automatically

## 5. Create And Rename Flow

### 建立隊伍

- uses text input dialog when invoked from legacy input flow
- closes automatically only after success

### 修改隊名

- uses text input dialog
- closes automatically only after success

## 6. Confirmations

Current second-confirmation coverage:
- disband party
- kick member
- reject party application
- reject party invite

Transfer leader:
- only the final confirmation is kept
- the earlier duplicate confirmation was removed

## 7. Terminology Updates

Current frontend copy:
- `修改隊名`
- `請離隊伍` instead of old kick copy

## 8. Important Role Rules

- A player who receives a party invite must respond from `待回應邀請`.
- The party leader does not approve the party's own outgoing invites.
- Join applications are reviewed by the party leader.
- Party members may read review data but cannot confirm it.

## 9. Related Backend Rule Reflected In UI

When a player is successfully added to a party:
- that player's other pending party applications and invites should be cleared server-side

The frontend assumes backend is the source of truth for this cleanup.

## 10. API Surface Used By Client

- `GET /api/party/my`
- `GET /api/party/{id}/cheer`
- `POST /api/party`
- `PUT /api/party/{id}/name`
- `DELETE /api/party/{id}`
- `DELETE /api/party/{id}/leave`
- `POST /api/party/{id}/transfer-leadership`
- `POST /api/party/{id}/kick/{targetUserId}`
- `POST /api/party/apply`
- `DELETE /api/party/application/{id}`
- `GET /api/party/{id}/applications`
- `POST /api/party/application/{id}/accept`
- `POST /api/party/application/{id}/reject`
- `GET /api/party/{id}/invite-candidates`
- `POST /api/party/{id}/invite`
- `POST /api/party/invite/{id}/accept`
- `POST /api/party/invite/{id}/reject`
- `POST /api/party/{id}/cheer`
- `POST /api/party/cheer-coupon/use`

Entry and recovery rule:
- The current frontend reads party data from `GameState` first.
- If bootstrap-backed party caches are unexpectedly missing while state says data should exist, the page may run targeted silent self-heal reads without restoring visible entry-time loading.
> Update 2026-04-21:
> Party cheer no longer adds the coupon directly to local inventory.
> The coupon is now received from mailbox, can be consumed from the idle reward dialog, and backpack ticket data is sourced from `partyCheerCouponCount` snapshots returned by bootstrap / wallet APIs.
> Coupon consumption feedback should reuse the same idle reward float presentation as normal idle reward claim, instead of summarizing rewards with a success toast.
