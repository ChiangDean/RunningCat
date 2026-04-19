# 23. Friend System

> Update 2026-04-19:
> Friends now open as an overlay scene with the shared bottom submenu.
> Submenu labels are `好友列表`、`待回應的申請`、`我提出的申請`.
> Add-friend now uses player-name search, not direct UID input.

## 1. Feature Summary

The friend system covers:
- friend list display
- incoming friend requests
- outgoing friend requests
- add-friend search
- remove friend
- one-key gifting

Current UI entry:
- Home HUD opens `FriendScene.tscn`.
- The page uses the same overlay style as `鏟屎官`、`主子`、`活動`.

## 2. Bottom Submenu

Shared submenu sections:
- `好友列表`
- `待回應的申請`
- `我提出的申請`

Section meaning:
- `好友列表`: current friends
- `待回應的申請`: requests received by the current player
- `我提出的申請`: requests sent by the current player and still pending

## 3. Friend List Layout

The friend list row now shows:
- small `刪除` button at the far left
- avatar
- scooper name
- scooper level
- current stage text
- last login time
- gift status

Current stage text format:
- uses the shared stage formatter
- example: `新手 I 4-4`

Gift status text:
- `未送禮`
- `已送禮`

Sorting:
1. Friends who are still `未送禮` come first.
2. Within the same gift state, more recently online players come first.
3. Then fallback sort by display name.

Removed from UI:
- `設定展示` button
- showcase-cat setup entry
- friend page refresh button

## 4. Add Friend Flow

Current flow:
1. Press `加好友`.
2. Open an `xlarge` dialog.
3. Enter target player name.
4. Client calls friend search API.
5. Candidate list is shown in a scrollable result list with inertial scrolling.
6. Press `加好友` on a candidate row to send the request.

Candidate row fields:
- avatar
- player name
- scooper level
- UID
- last login time

Search API:
- `GET /api/friend/search-candidates?query=...`

Search filtering:
- exclude self
- exclude players already in friend list
- exclude players with pending requests in either direction

## 5. Friend Request Flows

### 5.1 Incoming Requests

Incoming requests are shown under `待回應的申請`.

Allowed actions:
- `接受`
- `拒絕`

Reject flow:
- requires second confirmation before calling reject API

### 5.2 Outgoing Requests

Outgoing requests are shown under `我提出的申請`.

Allowed action:
- `取消申請`

## 6. One-Key Gift Flow

The top action row in `好友列表` contains:
- `加好友`
- `一鍵送禮`

One-key gift rules:
- Enabled if at least one friend is still `未送禮`.
- Disabled if all friends are already `已送禮`.
- Confirmation dialog counts only ungifted recipients.

After success:
- gifted rows update to `已送禮`
- button disables if no ungifted friend remains

## 7. Remove Friend Flow

Current behavior:
- `刪除` button is small and placed at the far left of the row
- removing a friend uses a single confirmation
- the old duplicate confirmation was removed

## 8. API Surface Used By Client

Current client friend APIs:
- `GET /api/friend`
- `GET /api/friend/request/inbox`
- `GET /api/friend/request/outbox`
- `GET /api/friend/search-candidates`
- `POST /api/friend/request`
- `POST /api/friend/request/{id}/accept`
- `POST /api/friend/request/{id}/reject`
- `DELETE /api/friend/request/{id}`
- `DELETE /api/friend/{friendUserId}`
- `POST /api/friend/gift/send-all`

## 9. Notes

- The backend still keeps showcase-cat related endpoints, but the current frontend no longer exposes that feature.
- Friend list empty state uses a single clean empty message instead of nested boxed placeholders.
