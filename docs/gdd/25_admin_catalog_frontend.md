# 25. Admin Catalog Frontend

> Last updated: 2026-04-17
> Audience: Godot client engineers and agents working on Admin-only tooling

## 1. Scope

`Admin Catalog` is an Admin-only overlay scene for editing server-side catalog and static configuration data.

Current implementation files:

- `res://scripts/configs/ConfigScene.gd`
- `res://scripts/configs/AdminCatalogScene.gd`
- `res://scenes/AdminCatalogScene.tscn`
- `res://scripts/ApiClient.gd`
- `res://scripts/gamestate/GameState.gd`

This page is intentionally outside the normal player bootstrap flow. Every entry to the page re-validates the session against protected Admin APIs before any catalog payload is shown.

## 2. Entry And Visibility

Entry point:

- `ConfigScene.gd` adds an `Admin Catalog` row inside the settings center.

Visibility rule:

- The row is only rendered when `GameState.is_admin_session()` returns `true`.
- `GameState.is_admin_session()` accepts either:
  - `roleType = admin`
  - `role = admin`
  - permission list containing `catalog.manage`

This keeps the entry hidden for normal players while still allowing permission-driven Admin sessions.

## 3. Access Validation Flow

Security requirement:

- The Admin page does not reuse player bootstrap payloads as its data source.
- `AdminCatalogScene._ready()` immediately calls `ApiClient.admin_get_catalog_access(...)`.

API:

- `GET /api/admin/catalog/access`

Behavior:

1. Scene opens.
2. Client calls `admin_get_catalog_access`.
3. If the request fails or returns unauthorized, the scene shows an error dialog and returns to the normal flow.
4. If the request succeeds, the returned section list and reference metadata drive the UI.
5. The first allowed section is loaded by `GET /api/admin/catalog/{section}`.

Result:

- Each visit re-checks identity and permission at the server boundary.
- Admin catalog data is never sourced from stale local bootstrap cache.

## 4. Scene Structure

`AdminCatalogScene.tscn` is a thin root scene; the UI is built in code by `AdminCatalogScene.gd`.

Layout:

- overlay chrome from `OverlaySceneChrome`
- top title and status line
- left section navigation list
- right editor panel with:
  - section title
  - section hint
  - action buttons: save / reload / discard
  - payload editor
  - reference sidebar

Current v1 editor mode:

- The scene is section-based, but the payload editor itself is a JSON editor.
- This allows Admins to add, modify, and disable parent/child rows without exposing raw SQL or direct DB access.
- References for common FK targets are rendered beside the editor to reduce lookup mistakes.

## 5. Client Interaction Rules

Supported actions:

- load allowed sections
- load one section payload
- modify payload locally
- confirm before save
- reload current section
- discard unsaved edits
- warn before switching sections or leaving with dirty state

Important UX rules:

- `Save` is disabled while loading/saving or when there are no local changes.
- `Reload` and `Discard` are protected by unsaved-change checks.
- Back navigation prompts if the editor is dirty.
- Save always goes through a confirmation dialog because the backend applies changes immediately.

## 6. ApiClient Contract

The client uses three dedicated methods:

- `admin_get_catalog_access(callback)`
- `admin_get_catalog_section(section_key, callback)`
- `admin_save_catalog_section(section_key, payload, callback)`

HTTP mapping:

- `GET admin/catalog/access`
- `GET admin/catalog/{section}`
- `PUT admin/catalog/{section}`

The client does not compose transaction payloads from multiple endpoints. Each section is fetched and saved as one aggregate payload.

## 7. GameState And Cache Boundary

`GameState` is used for session identity only:

- permission check for showing the entry
- bearer token reuse through `ApiClient`

`GameState` is not used as a cache for admin catalog payloads.

Cache boundary:

- access payload lives only in `AdminCatalogScene`
- section payload lives only in `AdminCatalogScene`
- every scene entry re-fetches access
- section data is re-fetched on demand

This keeps admin data consistent with server-side cache invalidation after save.

## 8. Error Handling

Failure handling rules:

- `access` failure: show dialog, reject page entry, return to normal scene flow
- section load failure: keep current UI, show dialog
- malformed JSON: block save locally
- save failure: keep edited content, show backend message

The page does not attempt optimistic local reconciliation. The server response after save is treated as the source of truth and replaces the current editor payload.

## 9. Acceptance Checklist

- Non-admin sessions do not see the `Admin Catalog` entry.
- Admin sessions always re-validate through `GET /api/admin/catalog/access`.
- Section payloads are loaded from protected admin endpoints, not bootstrap.
- Dirty navigation prompts work for section switch, reload, and back.
- Save requires explicit confirmation.
- Successful save refreshes the editor with the normalized backend payload.
- Failed save preserves local edits for correction and retry.
