# MeowPartyDashClient Rules

- This file is the persistent note for stable client-specific constraints and implementation reminders.
- Record only durable project rules here; do not use it for one-off tasks or temporary experiments.
- Preserve the established visual identity of `StartScene` unless the user explicitly asks to change it.
- When updating `StartScene`, treat the legacy title block, loading block, tap-to-start placement, and loading timing as separate behaviors; do not change them unless requested.
- Keep Godot client changes in GDScript and follow existing scene/script patterns already used in this project.
- Before making Client frontend architecture, UI flow, scene flow, or shared-state changes, first read `docs/gdd/18_frontend_architecture.md`.
- Prefer adding small, explicit UI state transitions instead of rewriting whole scene flows when only one stage changes.
- Runtime API config is environment-specific: CI generates `config/runtime_config.json`, while local development may override with ignored `config/runtime_config.local.json`.
- Persistent local runtime data such as login session and player save files must use `user://`, not `res://`.
- When new stable project-specific constraints are discovered during work, record them here so future changes stay consistent.
