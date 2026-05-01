# Asset Storage Layout

This folder is transitioning from the legacy layout:

- `assets/sprites/ui/**`
- `assets/sprites/battle/**`

to the long-term split defined in:

- `docs/gdd/29_asset_storage_cdn_strategy.md`

Target structure:

- `assets/sprites/local/**`
- `assets/sprites/cdn/**`

Rules:

1. Put startup, battle, shared UI skeleton, warning, and oauth assets under `local`.
2. Put preview art, character refs, card art, memory art, gacha art, and other late-load content under `cdn`.
3. During the transition, existing legacy paths may still be used by runtime code. Do not bulk-move old files until the corresponding `AssetResolver`, CI sync, and Web export rules are updated.
4. Before creating new art, check `config/cdn_asset_manifest.json` and `docs/gdd/29_asset_storage_cdn_strategy.md`.
5. The first migrated CDN folders already live under `assets/sprites/cdn/ui/character_refs`, `assets/sprites/cdn/ui/memory`, `assets/sprites/cdn/ui/cards`, and `assets/sprites/cdn/ui/gacha`; place new art for those categories there instead of the legacy `assets/sprites/ui/` paths.
6. The second migrated CDN groups now also live under `assets/sprites/cdn/ui/arena_ranks`, `assets/sprites/cdn/ui/dungeon`, `assets/sprites/cdn/ui/scooper_equipment`, `assets/sprites/cdn/ui/scooper_abilities`, and `assets/sprites/cdn/ui/treasure`.
7. For `assets/sprites/ui/rewards`, only the late-load reward icons belong in CDN. Keep `collision_coin`, `diamonds`, `evil_cat_power_icon`, `money`, `poop_count`, slot frames, and masks in local paths.
8. Activity preview backgrounds and late-load page backgrounds now belong under `assets/sprites/cdn/ui/activity`.
9. Keep `start_scene_homey_v1.png`, `battle_background_homey_v1.png`, and `combat_trial/bath_trial_bg.svg` in local paths.
