# 18. Frontend Architecture

> Last updated: 2026-04-11
> Audience: AI agents and engineers modifying `MeowPartyDashClient`

This document describes the current frontend architecture of `MeowPartyDashClient` so an AI agent can quickly find the correct edit location, understand data flow, and avoid breaking existing project conventions.

---

## 1. Project Summary

- Frontend project path: `MeowPartyDashClient/`
- Engine: Godot 4.6
- Primary language: GDScript
- .NET project exists for Godot integration, but current gameplay/frontend logic is implemented in GDScript
- Main entry scene: `res://scenes/StartScene.tscn`
- Theme resource: `res://resources/default_theme.tres`
- Runtime viewport baseline: `720 x 1280`

Important rule: most gameplay and UI surfaces are generated directly in GDScript at runtime instead of being heavily authored in `.tscn` files. In many cases, the `.tscn` file is only a root node plus a script attachment.

---

## 2. Runtime Entry Points

### 2.1 Godot Entry

Defined in `project.godot`:

- `run/main_scene = res://scenes/StartScene.tscn`
- Autoload singletons:
  - `GameState = res://scripts/gamestate/GameState.gd`
  - `DialogManager = res://scripts/DialogManager.gd`
  - `ApiClient = res://scripts/ApiClient.gd`

### 2.2 Start Flow

Primary startup logic lives in:

- `scripts/StartScene.gd`

Responsibilities:

- build the login/register/start UI in code
- resolve runtime API base URL from config files
- load or create local device id
- restore persisted auth session from `GameState`
- run authenticated bootstrap if a valid session exists
- transition into the main gameplay flow after login/bootstrap

Project rule from `AGENTS.md`: preserve the established visual identity of `StartScene` unless the task explicitly requires changing it.

---

## 3. Top-Level Directory Map

### 3.1 Scene Definitions

- `scenes/`

Contains top-level scene entry files such as:

- `StartScene.tscn`
- `BattleScene.tscn`
- `ActivityScene.tscn`
- `DungeonScene.tscn`
- `ArenaScene.tscn`
- `ArenaBattleScene.tscn`
- `ConfigScene.tscn`
- `EnhanceScene.tscn`
- `GachaScene.tscn`
- `ShopScene.tscn`
- `ScooperScene.tscn`
- `LevelScene.tscn`

These usually serve as entry wrappers for a paired script.

### 3.2 Frontend Scripts

- `scripts/`

Main codebase for client behavior. Key subfolders:

- `scripts/gamestate/`: app-wide state, persistence, cache helpers
- `scripts/battle/`: battle runtime, simulator, manager, battle scenes
- `scripts/arenaScene/`: arena UI shell and helpers
- `scripts/dungeon/`: dungeon UI split into shell, UI builder, and action handlers
- `scripts/enhance/`: enhance UI split into shell, UI builder, refresh logic, and actions
- `scripts/gacha/`: gacha flow and result panel
- `scripts/shop/`: shop menu and subviews
- `scripts/scooper/`: scooper scene and per-tab logic
- `scripts/configs/`: config/team setup scene
- `scripts/data/`: frontend-side data models and data adapters
- `scripts/cats/`: cat runtime classes and type-specific behavior
- `scripts/managers/`: registries for cats and skills
- `scripts/systems/`: local systems such as idle, arena rank, gacha, special ability
- `scripts/ui/`: reusable UI helpers such as inertial scrolling

### 3.3 Static Assets

- `assets/`

Current structure:

- `assets/fonts/`: fonts
- `assets/audio/`: audio
- `assets/sprites/ui/`: UI visuals, backgrounds, icons, poses

### 3.4 Static Data and Runtime Samples

- `data/`

Current structure:

- `data/default/`: static default config JSON
- `data/default/cats/`: cat definitions in JSON
- `data/default/skills/`: active/passive skill definitions in JSON
- `data/arena/`: arena seed/test data
- `data/saves/`: local sample or persisted save-oriented data inside repo

### 3.5 Config and Docs

- `config/`: runtime config templates
- `docs/gdd/`: game and architecture documents for implementation reference

---

## 4. Architectural Layers

The frontend is easiest to reason about as five layers:

1. Scene shell layer
2. Feature UI/action helper layer
3. Service layer
4. State and cache layer
5. Static data layer

### 4.1 Scene Shell Layer

Representative files:

- `scripts/StartScene.gd`
- `scripts/ActivityScene.gd`
- `scripts/LevelScene.gd`
- `scripts/dungeon/DungeonScene.gd`
- `scripts/enhance/EnhanceScene.gd`
- `scripts/arenaScene/ArenaScene.gd`
- `scripts/shop/ShopScene.gd`
- `scripts/gacha/GachaScene.gd`

Typical responsibilities:

- build top-level UI
- wire button navigation
- call feature actions
- read already-loaded state from `GameState`
- trigger API refresh if needed

### 4.2 Feature Helper Layer

Used when a screen is large enough to split responsibilities.

Examples:

- `scripts/dungeon/DungeonSceneUI.gd`
- `scripts/dungeon/DungeonSceneActions.gd`
- `scripts/enhance/EnhanceSceneUI.gd`
- `scripts/enhance/EnhanceSceneRefresh.gd`
- `scripts/enhance/EnhanceSceneActions.gd`
- `scripts/arenaScene/arena_scene_helpers.gd`
- `scripts/arenaScene/arena_scene_reward_popup.gd`

Pattern:

- `Scene.gd` acts as the shell/controller
- `*UI.gd` builds and refreshes UI
- `*Actions.gd` performs API-triggered actions and handles result callbacks
- helper files format labels, reward popups, or feature-specific transforms

### 4.3 Service Layer

Primary service:

- `scripts/ApiClient.gd`

Responsibilities:

- owns a small `HTTPRequest` pool
- queues requests when all slots are busy
- applies bearer token headers
- parses API envelopes
- handles `401` by refreshing with refresh token and retrying
- exposes feature-specific convenience methods instead of forcing scenes to build URLs manually

The rest of the frontend should prefer calling `ApiClient` convenience methods, not constructing ad hoc HTTP logic in scene scripts.

### 4.4 State and Cache Layer

Primary state owner:

- `scripts/gamestate/GameState.gd`

Supporting helpers:

- `scripts/gamestate/GameStateCacheIO.gd`
- `scripts/gamestate/GameStateFileUtils.gd`
- `scripts/gamestate/GameStateBossStage.gd`

Responsibilities:

- owns auth session and API base URL
- applies bootstrap payloads
- stores current player-facing state
- persists cache files under `user://`
- exposes accessors used by scenes
- keeps feature overviews in memory after API refresh

### 4.5 Static Data Layer

Primary static loader:

- `scripts/data/static_game_data.gd`

This layer provides local default configuration such as:

- cat definitions
- active/passive skill definitions
- dungeon config
- arena config
- idle config

Use this layer when data is part of shipped client defaults, not player-specific live state.

---

## 5. State Ownership Rules

### 5.1 Global Singleton Ownership

`GameState` is the main source of truth for runtime state that must survive scene changes.

Examples of state currently owned there:

- auth session
- `player_data`
- player cat and enhance data
- team config data
- dungeon overview
- arena overview
- gacha overview
- shop overview
- scooper catalog data
- scooper live data

If a feature needs to be read by multiple scenes or must survive scene transitions, it usually belongs in `GameState`.

### 5.2 Scene-Local Ownership

Scene-local transient state should stay in the scene script when it is only used for temporary UI behavior.

Examples:

- selected tab
- currently expanded panel
- draft edits before save
- request-in-flight flags
- cooldown timers

Do not put temporary widget state into `GameState` unless multiple scenes depend on it.

---

## 6. Data Sources and Persistence

Frontend data comes from four places:

1. hardcoded/static config in script
2. JSON files under `res://data/default/`
3. API responses
4. cached/persisted runtime files under `user://`

### 6.1 Static Config

Loaded through `StaticGameData` and repo JSON/config files.

Common sources:

- `scripts/data/static_game_data.gd`
- `data/default/*.json`
- `data/default/cats/*.json`
- `data/default/skills/**/*.json`

### 6.2 Auth and Runtime Config

Key files:

- `config/runtime_config.example.json`
- `config/runtime_config.local.example.json`
- runtime reads:
  - `res://config/runtime_config.json`
  - `res://config/runtime_config.local.json`

Rule: CI-generated runtime config and local override config are environment-specific. Do not hardcode production URLs into random scene scripts.

### 6.3 Persistent `user://` Storage

Important persisted paths used by frontend architecture:

- `user://auth_session.json`
- `user://device_id.txt`
- `user://catalog/*.json`
- `user://config/*.json`
- `user://player_data/scooper/*.json`

Player-specific runtime persistence should flow through `PlayerData`, per-cat save files, and `GameState` cache files under `user://`. Arena and dungeon overview state should not read from repo-local save JSON.

Project rule: persistent local runtime data must use `user://`, not `res://`.

### 6.4 API Envelope Shape

`ApiClient.gd` expects JSON responses shaped like:

```json
{
  "success": true,
  "data": {},
  "error": {}
}
```

Scenes and action handlers should work with the `data` payload delivered by `ApiClient`, not raw HTTP body parsing.

---

## 7. Main Data Flow

### 7.1 Bootstrap Flow

Normal authenticated startup:

1. `StartScene.gd` resolves API base URL and device/session state
2. auth succeeds or persisted session is restored
3. bootstrap API returns player snapshot plus feature overviews/catalogs
4. `GameState.apply_player_bootstrap(data)` writes runtime state
5. `GameState` persists relevant cache files under `user://`
6. later scenes read from `GameState` first and refresh from API only when needed

### 7.2 Scene Refresh Flow

Typical feature refresh path:

1. scene opens
2. scene reads cached `GameState` state
3. if state is missing or stale, scene calls `ApiClient`
4. callback updates `GameState`
5. scene rebuilds or refreshes UI from updated `GameState`

This is the dominant frontend pattern.

### 7.3 Mutating Action Flow

Typical action path:

1. user presses button
2. scene or `*Actions.gd` calls `ApiClient`
3. server returns updated overview or changed entities
4. callback writes response into `GameState`
5. UI refreshes from `GameState`

Do not manually patch many labels from raw response if the feature already has a `GameState.update_*()` path. Prefer updating shared state first, then re-rendering.

---

## 8. Navigation Map

Current high-level navigation is scene-to-scene via `get_tree().change_scene_to_file(...)`.

Common flow:

- `StartScene` -> `BattleScene`
- `BattleScene` bottom nav opens:
  - `ScooperScene`
  - `ConfigScene`
  - `EnhanceScene`
  - `ActivityScene`
  - `ShopScene`
- `ActivityScene` opens:
  - `DungeonScene`
  - `ArenaScene`
- `ShopScene` can open:
  - `GachaScene`
- battle-specific routes also open:
  - `ArenaBattleScene`
  - `DungeonBattleScene`

There is no central router object. Navigation is currently distributed across scene scripts.

---

## 9. Feature Ownership Map

Use this section to find the correct edit surface quickly.

### 9.1 Auth / Startup

- `scripts/StartScene.gd`
- `scripts/ApiClient.gd`
- `scripts/gamestate/GameState.gd`
- `config/runtime_config*.json`

### 9.2 Core Battle

- `scripts/battle/battle_scene.gd`
- `scripts/battle/battle_manager.gd`
- `scripts/battle/battle_simulator.gd`
- `scripts/battle/battle_event.gd`
- `scripts/cats/`
- `scripts/systems/special_ability_system.gd`

### 9.3 Team Config

- `scripts/configs/ConfigScene.gd`
- `scripts/configs/ConfigConstants.gd`
- `scripts/gamestate/GameState.gd`
- related doc: `docs/gdd/15_config_data_architecture.md`

### 9.4 Enhance

- `scripts/enhance/EnhanceScene.gd`
- `scripts/enhance/EnhanceSceneUI.gd`
- `scripts/enhance/EnhanceSceneRefresh.gd`
- `scripts/enhance/EnhanceSceneActions.gd`

### 9.5 Dungeon

- `scripts/dungeon/DungeonScene.gd`
- `scripts/dungeon/DungeonSceneUI.gd`
- `scripts/dungeon/DungeonSceneActions.gd`
- `scripts/gamestate/GameState.gd`
- related doc: `docs/gdd/16_dungeon_data_architecture.md`

### 9.6 Arena

- `scripts/arenaScene/ArenaScene.gd`
- `scripts/arenaScene/arena_scene_helpers.gd`
- `scripts/arenaScene/arena_scene_reward_popup.gd`
- `scripts/battle/arena_battle_scene.gd`
- `scripts/gamestate/GameState.gd`
- related doc: `docs/gdd/17_arena_data_architecture.md`

### 9.7 Scooper

- `scripts/ScooperScene.gd`
- `scripts/scooper/`
- `scripts/ApiClient.gd`
- `scripts/gamestate/GameState.gd`
- related doc: `docs/gdd/14_scooper_data_architecture.md`

### 9.8 Gacha / Shop

- `scripts/gacha/GachaScene.gd`
- `scripts/gacha/GachaResultPanel.gd`
- `scripts/shop/ShopScene.gd`
- `scripts/shop/ShopTrapCageView.gd`
- `scripts/shop/ShopBundleView.gd`
- `scripts/gamestate/GameState.gd`

---

## 10. Current Frontend Conventions

These conventions are important when AI agents make changes.

### 10.1 Build UI in Script First

Many screens are code-built. Before assuming a `.tscn` contains the UI tree, inspect the paired `.gd` file.

### 10.2 Prefer Small Feature Splits

When a screen becomes large, the existing pattern is to split into:

- shell scene script
- UI builder helpers
- refresh helpers
- action handlers

Prefer following that pattern instead of introducing a new architecture style for one screen only.

### 10.3 Use Autoloads for Shared Services

Common shared dependencies should go through:

- `GameState`
- `ApiClient`
- `DialogManager`

Do not create duplicate global state containers for the same concern.

### 10.4 Persist Through `GameState`

If API data needs to survive scene changes, add or update a `GameState.update_*()` style path and persist via `GameStateCacheIO` if applicable.

### 10.5 Keep Feature-Specific State Local

Do not pollute `GameState` with one-screen-only toggles, scroll positions, or draft widget flags.

### 10.6 Respect Existing Scene Boundaries

Examples:

- `EnhanceScene` is already split into UI, refresh, and actions
- `DungeonScene` is already split into UI and actions
- `ArenaScene` keeps helper formatting in a separate helper file

Extend the existing boundary before inventing another one.

---

## 11. Safe Change Guide For AI Agents

### 11.1 If You Need To Change API-Driven UI

Check in this order:

1. scene shell file
2. related `*Actions.gd` or helper file
3. `ApiClient.gd`
4. `GameState.gd`
5. related `docs/gdd/*_architecture.md`

### 11.2 If You Need To Add A New Persisted API Feature

Expected work usually includes:

1. add `ApiClient` convenience method
2. add `GameState` state fields and update method
3. add cache save/load if the data should persist locally
4. update scene/action files to read from `GameState`
5. update architecture docs if the data flow becomes durable

### 11.3 If You Need To Change Visual Layout

Check whether the screen is:

- mostly code-built in `.gd`
- partially composed from helper files
- constrained by an existing visual identity such as `StartScene`

### 11.4 If You Need To Change Navigation

Search for `change_scene_to_file` in the related scene scripts. Navigation is decentralized.

---

## 12. Paths AI Should Inspect First

When an AI agent needs orientation, inspect these files first:

- `project.godot`
- `AGENTS.md`
- `scripts/StartScene.gd`
- `scripts/ApiClient.gd`
- `scripts/gamestate/GameState.gd`
- `scripts/gamestate/GameStateCacheIO.gd`
- `scripts/data/static_game_data.gd`

Then inspect the feature-specific scene and helper folder.

---

## 13. Non-Goals And Things To Avoid

- Do not assume `.tscn` files fully describe the UI
- Do not store persistent runtime data in `res://`
- Do not bypass `ApiClient` with random per-scene HTTP implementations unless there is a strong architectural reason
- Do not duplicate global state that already belongs to `GameState`
- Do not rewrite `StartScene` visual identity unless explicitly requested
- Do not move frontend logic into C# unless the task explicitly requires changing the technology boundary

---

## 14. Related Documents

- `docs/gdd/08_ui.md`
- `docs/gdd/14_scooper_data_architecture.md`
- `docs/gdd/15_config_data_architecture.md`
- `docs/gdd/16_dungeon_data_architecture.md`
- `docs/gdd/17_arena_data_architecture.md`

This document should be updated whenever the client introduces a new durable frontend subsystem, a new global singleton, or a materially different data flow pattern.
