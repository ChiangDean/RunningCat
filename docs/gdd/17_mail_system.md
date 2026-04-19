# 17. Mail System

> Update 2026-04-19:
> Mail now opens as an overlay scene, not a dialog.
> The shared bottom submenu only keeps `未讀郵件` and `已讀郵件`.
> Expired mail is excluded from all client mail lists.

## 1. Feature Summary

Mail is the player inbox for system rewards, compensation, event rewards, purchases, and friend gifts.

Current frontend behavior:
- Mail summary and inbox snapshot are loaded during authenticated bootstrap.
- Entering the mail page should reuse `GameState.mail_summary_data` and `GameState.mail_list_data` instead of re-requesting summary, list, or detail.
- After login, mail changes should replace the cached summary + inbox snapshot through websocket `mail.sync`.
- If summary says mail exists but cached inbox data is missing or stale, the page may run a silent self-heal fetch without showing the shared loading overlay.
- Entry opens `MailOverlayScene.tscn` from the home HUD.
- The page uses the same overlay chrome and shared bottom submenu pattern as `鏟屎官`、`主子`、`活動`.
- Sections are:
  - `未讀郵件`
  - `已讀郵件`
- Expired mail is not shown.
- The right content pane only shows:
  - title
  - content
  - attachments
  - remaining days before expiry

## 2. Scene Structure

Primary controller: `scripts/MailScene.gd`

Wrapper scene:
- `scenes/MailOverlayScene.tscn`
- `scripts/MailOverlayScene.gd`

Content scene:
- `scripts/MailScene.gd`

Layout:
- top action row
  - `一件領收`
  - `刪除已讀郵件`
- left column
  - mail title list only
- right column
  - title
  - content card
  - expiry label at bottom-right
  - attachment list
  - `領取附件` button when applicable

## 3. Bottom Submenu

The bottom submenu uses the shared scene submenu component.

Sections:
- `未讀郵件`
- `已讀郵件`

Rules:
- `未讀郵件` includes mail that is not fully processed yet.
- `已讀郵件` includes mail that is already read and either:
  - attachment already claimed
  - or the mail never had an attachment

## 4. Left Column Rules

The left column is a mail selector list.

Display rules:
- Only the title is shown.
- Title is fixed to one line.
- Overflow text is trimmed with `...`.
- Font size follows the same smaller list presentation used by the store secondary menus.
- Unread mail shows a small unread indicator dot.
- Selecting a mail highlights the card.

Empty state:
- Show `目前沒有郵件`.
- Do not create an extra nested empty-state frame.

## 5. Right Column Rules

The right pane displays the selected mail.

Shown fields:
- title
- content
- attachments
- `剩餘X天過期`

Removed fields:
- mail type
- status
- raw expire timestamp

Attachment button rules:
- If the mail has no attachment, hide `領取附件`.
- If the mail attachment is already claimed, hide `領取附件`.
- If the mail can be claimed, show `領取附件`.

## 6. Actions

### 6.1 Read Mail

Flow:
1. Render the left list from `GameState.mail_list_data`.
2. Select a mail from the cached inbox snapshot first.
3. If the selected row is missing detail fields unexpectedly, silently request detail through `GET /api/mail/{mailId}` without showing entry-time loading.
4. If the mail was unread, client marks it locally first.
5. Then client calls `POST /api/mail/{mailId}/read`.

Result:
- Mail moves from `未讀郵件` to `已讀郵件` when it becomes processed under the current rule set.
- A mail without attachment enters `已讀郵件` immediately after being read.

### 6.2 Claim Attachment

Flow:
1. Player presses `領取附件`.
2. Client calls `POST /api/mail/{mailId}/claim`.
3. Wallet snapshot and mail summary are refreshed.
4. Attachment button disappears after success.

### 6.3 一件領收

Flow:
1. Player presses `一件領收`.
2. Client shows a confirm dialog.
3. Confirm calls `POST /api/mail/claim-all`.
4. All currently claimable attachments are claimed.

Button enablement:
- Enabled only when `claimableCount > 0`.
- Otherwise disabled.

### 6.4 刪除已讀郵件

Flow:
1. Player presses `刪除已讀郵件`.
2. Client shows a confirm dialog.
3. Confirm calls `DELETE /api/mail/read`.
4. All mails that are already processed are removed from the visible inbox.

Button style:
- Uses the shared danger button style.

Button enablement:
- Enabled only when at least one processed mail exists.

## 7. Filtering Rules

### 7.1 Expired Mail

Frontend excludes expired mail from:
- unread list
- read list
- selected mail display fallback after reload

If detail returns an expired item:
- clear current selection
- refresh list

### 7.2 Processed Mail

Processed mail means:
- `isRead == true`
- and `isClaimed == true` or `hasAttachment == false`

This rule is shared by:
- read section display
- delete read mail availability

## 8. API Surface Used By Client

Current client uses:
- `GET /api/mail/summary`
- `GET /api/mail`
- `GET /api/mail/{mailId}`
- `POST /api/mail/{mailId}/read`
- `POST /api/mail/{mailId}/claim`
- `POST /api/mail/claim-all`
- `DELETE /api/mail/read`

Entry rule:
- Auth bootstrap and websocket `mail.sync` are the primary source for inbox rendering.
- Explicit `GET /api/mail` and `GET /api/mail/{mailId}` are now fallback / self-heal reads, not mandatory page-entry requests.

## 9. GameState Data

Mail UI depends on:
- `GameState.mail_summary_data`
- `GameState.mail_list_data`
- `GameState.selected_mail_data`

Client-side local update helpers are used after actions such as:
- mark read
- claim single
- claim many

## 10. UX Notes

- Mail no longer uses the old dialog-style mail surface.
- Top-right actions are placed above the two-column body, not inside the right pane.
- Attachment reward popup may still be shown after successful claim, but the main mail surface stays in overlay-scene flow.
