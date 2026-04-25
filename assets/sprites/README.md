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
