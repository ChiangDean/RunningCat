# 24. Stats Dialog

> Last updated: 2026-04-19
> Audience: AI agents and engineers modifying `MeowPartyDashClient`

This document describes the current frontend implementation for the home-screen stats entry opened from the battle home quick menu.

---

## Summary

- Entry point button: the `stats` quick button inside `scripts/battle/battle_scene.gd`
- Open behavior: use `DialogManager.show_info_node(...)`
- Scene file: `res://scenes/StatsScene.tscn`
- Script file: `res://scripts/StatsScene.gd`
- Layout style: left secondary submenu plus right detail panel

The previous in-battle floating `StatsPanel` implementation has been retired. The stats feature now follows the same dialog-open pattern used by the mail dialog so the interaction model is consistent.

---

## Open Flow

1. The player presses the `stats` quick button in the home quick menu.
2. `battle_scene.gd` instantiates `StatsScene.tscn`.
3. The scene is opened through `DialogManager.show_info_node(...)` with `xlarge` width.
4. `StatsScene.gd` receives a close callback so its back button dismisses the dialog instead of changing the whole scene.

---

## UI Structure

`StatsScene.gd` builds the interface directly in GDScript.

- Top header row
  - back button
  - title label
- Main body
  - left secondary submenu
  - right scrollable detail content

The left submenu uses the same reusable secondary-submenu pattern as other modern overlay-style client pages.

Current tabs:

- `all`
- `ability`
- `equipment`
- `memory`
- `treasure`
- `level`

---

## Data Sources

`StatsScene.gd` reads from `GameState` only. It does not fetch directly from API methods.

Primary sources:

- `GameState.get_special_ability_summary()`
- `GameState.get_treasure_effects()`
- `GameState.player_team`
- `GameState.scooper_equipment_data`
- `GameState.scooper_ability_data`
- `GameState.scooper_memory_data`
- `GameState.scooper_treasure_data`

The stats dialog is aggregate-first. It does not show per-item cards for abilities, equipment, memories, or treasures.

- Each tab shows only final effect lines.
- Matching effects are merged before rendering.
- Live scooper bootstrap arrays are preferred when available so owned equipment, unlocked memories, owned treasures, and owned special abilities stay aligned with backend bootstrap data.
- Raw stat keys such as `HpPercent`, `AtkPercent`, and `IdlePoopPercent` are normalized before aggregation.
- The `all` tab is rendered as a single merged list instead of multiple section cards.
- Typical output format is `HP +50`, `HP +12%`, `暴擊率 +8%`.
- Team passive effects are also aggregated before rendering.

---

## Team Passive Rendering

The `level` and `all` tabs render team passive effects for the currently deployed team as merged summary lines.

- Team members are read from `GameState.player_team`
- `GameState.get_cat_file_id(...)` resolves the runtime cat file id
- `CatData.from_json_file(...)` loads passive definitions
- `GameState.get_player_cat(...)` provides current rank for rank-scaling calculations

The result is aggregate-only output rather than per-cat passive cards.

---

## Maintenance Notes

- Keep the stats entry on the dialog path; do not reintroduce a separate floating panel unless explicitly requested.
- Keep the stats page aggregate-first unless the PM explicitly asks to inspect item-level detail.
- Prefer updating `StatsScene.gd` when changing stats presentation, tab structure, or fallback behavior.
- If future work changes the tab list or open behavior, update this document and `18_frontend_architecture.md`.
