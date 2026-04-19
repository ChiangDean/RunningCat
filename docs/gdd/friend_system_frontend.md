# Friend System Frontend

This file mirrors the current frontend behavior described in [23_friend_system.md](/C:/Users/Home/OneDrive/Desktop/MeowPartyDash/MeowPartyDashClient/docs/gdd/23_friend_system.md).

## Current Source Of Truth

Primary scene flow:
- `scenes/FriendScene.tscn`
- `scripts/social/FriendScene.gd`
- `scripts/social/SocialScene.gd`

Key points:
- open as overlay scene, not dialog
- use shared bottom submenu
- submenu is `好友列表` / `待回應的申請` / `我提出的申請`
- add-friend uses player-name search with scrollable candidate list
- friend rows show avatar, level, name, current stage, last login, gift status
- gift status sorts `未送禮` above `已送禮`
- `一鍵送禮` is enabled only when at least one friend is still ungifted
- `設定展示` has been removed from the current frontend UI

## Detail Rules

### 好友列表

Top actions:
- `加好友`
- `一鍵送禮`

Row layout:
- small `刪除` button
- avatar
- scooper display info
- last login
- `已送禮 / 未送禮`

### 待回應的申請

Shows incoming requests.

Actions:
- `接受`
- `拒絕`

`拒絕` requires secondary confirmation.

### 我提出的申請

Shows outgoing pending requests.

Action:
- `取消申請`

## API Surface

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
