# 18. Frontend Architecture

> Last updated: 2026-04-19
> Audience: AI agents and engineers modifying `MeowPartyDashClient`

This document describes the current frontend architecture of `MeowPartyDashClient` so an agent can quickly find the correct edit location, understand data flow, and avoid reintroducing the old `ConfigScene = team config` assumption.

---

## 1. Project Summary

- Frontend project path: `MeowPartyDashClient/`
- Engine: Godot 4.6
- Primary language: GDScript
- Main entry scene: `res://scenes/StartScene.tscn`
- Home shell scene: `res://scenes/HomeShellScene.tscn`
- Runtime viewport baseline: `720 x 1280`

Important rule: many UI surfaces are built directly in GDScript at runtime. A `.tscn` file is often only a root node plus a script attachment.

---

## 2. Runtime Entry Points

### 2.1 Godot Entry

Defined in `project.godot`:

- `run/main_scene = res://scenes/StartScene.tscn`
- Autoload singletons:
  - `GameState = res://scripts/gamestate/GameState.gd`
  - `DialogManager = res://scripts/DialogManager.gd`
  - `ApiClient = res://scripts/ApiClient.gd`
  - `ChatRealtimeClient = res://scripts/chat/ChatRealtimeClient.gd`
  - `SceneNavigator = res://scripts/navigation/SceneNavigator.gd`
  - `UiAudio = res://scripts/ui/UiAudio.gd`
  - `ClientSettings = res://scripts/gamestate/ClientSettings.gd`
  - `ToastManager = res://scripts/ui/ToastManager.gd`

### 2.2 Start Flow

Primary startup logic lives in:

- `scripts/StartScene.gd`

Responsibilities:

- build the login / register / restore-session UI in code
- resolve runtime API base URL from config files
- load or create local device id
- restore persisted auth session from `GameState`
- run authenticated bootstrap if a valid session exists
- transition into the home gameplay flow after login / bootstrap

Project rule from `AGENTS.md`: preserve the established visual identity of `StartScene` unless the task explicitly requires changing it.

---

## 3. Top-Level Directory Map

### 3.1 Scene Definitions

- `scenes/`

Current important top-level scenes:

- `StartScene.tscn`
- `HomeShellScene.tscn`
- `BattleScene.tscn`
- `ConfigScene.tscn` — real settings center
- `LineupScene.tscn` — team composition and delay setup
- `EnhanceScene.tscn`
- `ActivityScene.tscn`
- `DungeonScene.tscn`
- `ArenaScene.tscn`
- `ArenaBattleScene.tscn`
- `GachaScene.tscn`
- `ShopScene.tscn`
- `ScooperScene.tscn`
- `LevelScene.tscn`
- `MailOverlayScene.tscn`
- `StatsScene.tscn`
- `ChatScene.tscn`
- `FriendScene.tscn`
- `PartyScene.tscn`

### 3.2 Frontend Scripts

- `scripts/`

Main subfolders:

- `scripts/gamestate/`: global state, persistence, cache helpers, `ClientSettings`
- `scripts/battle/`: battle runtime, simulator, manager, battle scenes
- `scripts/arenaScene/`: arena UI shell and helpers
- `scripts/dungeon/`: dungeon UI split into shell, UI builder, and action handlers
- `scripts/enhance/`: enhance UI split into shell, UI builder, refresh logic, and actions
- `scripts/gacha/`: gacha flow and result panel
- `scripts/shop/`: shop menu and subviews
- `scripts/scooper/`: scooper scene and per-tab logic
- `scripts/StatsScene.gd`: dialog-style stats viewer opened from the battle home quick menu
- `scripts/configs/`: settings center scene
- `scripts/lineup/`: team setup scene and lineup constants
- `scripts/data/`: frontend-side data models and adapters
- `scripts/cats/`: cat runtime classes and type-specific behavior
- `scripts/managers/`: registries for cats and skills
- `scripts/systems/`: local systems such as idle, arena rank, gacha, special ability
- `scripts/ui/`: reusable UI helpers
- `scripts/MailOverlayScene.gd`: mailbox overlay wrapper that hosts the shared chrome and footer submenu
- `scripts/MailScene.gd`: mailbox content view used inside the overlay wrapper
- `scripts/chat/`: chat overlay scene, realtime socket client, channel tabs, and message row rendering

### 3.3 Static Assets

- `assets/`

Current structure:

- `assets/fonts/`
- `assets/audio/`
- `assets/sprites/ui/`

### 3.4 Static Data and Runtime Samples

- `data/`

Current structure:

- `data/default/`
- `data/default/cats/`
- `data/default/skills/`
- `data/arena/`
- `data/saves/`

### 3.5 Config and Docs

- `config/`: runtime config templates
- `docs/gdd/`: game and architecture documents

---

## 4. Architectural Layers

The frontend is easiest to reason about as six layers:

1. Scene shell layer
2. Feature UI / action helper layer
3. Service layer
4. Runtime state layer
5. Local device settings layer
6. Static data layer

### 4.1 Scene Shell Layer

Representative files:

- `scripts/StartScene.gd`
- `scripts/battle/battle_scene.gd`
- `scripts/configs/ConfigScene.gd`
- `scripts/lineup/LineupScene.gd`
- `scripts/arenaScene/ArenaScene.gd`
- `scripts/dungeon/DungeonScene.gd`
- `scripts/enhance/EnhanceScene.gd`
- `scripts/shop/ShopScene.gd`
- `scripts/gacha/GachaScene.gd`

Typical responsibilities:

- build top-level UI
- wire button navigation
- call feature actions
- read shared state from `GameState`
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

Pattern:

- `Scene.gd` acts as the shell / controller
- `*UI.gd` builds and refreshes UI
- `*Actions.gd` performs API-triggered actions and handles result callbacks

### 4.3 Service Layer

Primary service:

- `scripts/ApiClient.gd`

Responsibilities:

- owns the HTTP request pool
- applies bearer token headers
- parses API envelopes
- handles `401` by refreshing and retrying
- exposes feature-specific methods such as:
  - `get_profile_me(...)`
  - `update_profile_me(...)`
  - `redeem_code(...)`
  - `replace_team(...)`

Scenes should prefer `ApiClient` convenience methods, not hand-built HTTP code.

### 4.4 Runtime State Layer

Primary state owner:

- `scripts/gamestate/GameState.gd`

Responsibilities:

- owns auth session and API base URL
- applies bootstrap payloads
- stores player-facing runtime state
- persists cache files under `user://`
- exposes accessors used by scenes
- emits update signals when player profile or wallet changes

### 4.5 Local Device Settings Layer

Primary owner:

- `scripts/gamestate/ClientSettings.gd`

Responsibilities:

- loads and saves `user://client_settings.json`
- manages `masterVolume`, `bgmVolume`, `sfxVolume`
- manages `masterMuted`, `bgmMuted`, `sfxMuted`
- applies changes through `UiAudio.apply_settings(...)`

This data is device-local and intentionally does not go through backend persistence.

### 4.6 Static Data Layer

Primary static loader:

- `scripts/data/static_game_data.gd`

Use this layer when data is shipped client defaults, not player-specific live state.

---

## 5. State Ownership Rules

### 5.1 Global Singleton Ownership

`GameState` is the main source of truth for runtime state that must survive scene changes.

Examples:

- auth session
- `player_data`
- player profile fields used by settings center
- player cat and enhance data
- confirmed team config data
- dungeon overview
- arena overview
- gacha overview
- shop overview
- scooper catalog and live data

### 5.2 Device-Local Ownership

`ClientSettings` owns values that should persist on the device but should not sync to backend.

Examples:

- master volume
- BGM volume
- SFX volume
- muted flags

### 5.3 Scene-Local Ownership

Keep transient widget state in the scene when only that screen needs it.

Examples:

- selected tab
- request-in-flight flags
- lineup draft edits
- selected avatar card while form is dirty
- home scoop animation / cooldown / auto-scoop enabled state

Do not put one-screen-only widget state into `GameState` unless multiple scenes depend on it.

---

## 6. Data Sources and Persistence

Frontend data comes from five places:

1. hardcoded / script defaults
2. JSON files under `res://data/default/`
3. API responses
4. cached runtime files under `user://`
5. device-local settings under `user://client_settings.json`

### 6.1 Auth and Runtime Config

Key files:

- `config/runtime_config.example.json`
- `config/runtime_config.local.example.json`
- runtime reads:
  - `res://config/runtime_config.json`
  - `res://config/runtime_config.local.json`

### 6.2 Persistent `user://` Storage

Important paths:

- `user://auth_session.json`
- `user://device_id.txt`
- `user://catalog/*.json`
- `user://config/player_cats.json`
- `user://config/teams.json`
- `user://player_data/scooper/*.json`
- `user://client_settings.json`

Project rule: persistent runtime data must use `user://`, not `res://`.

### 6.3 API Envelope Shape

`ApiClient.gd` expects:

```json
{
  "success": true,
  "data": {},
  "error": {}
}
```

Scenes should work with the `data` payload delivered by `ApiClient`, not raw HTTP body parsing.

---

## 7. Main Data Flow

### 7.1 Bootstrap Flow

1. `StartScene.gd` resolves API base URL and device / session state
2. auth succeeds or persisted session is restored
3. bootstrap API returns player snapshot plus feature overviews
4. `GameState.apply_player_bootstrap(data)` writes runtime state
5. `GameState` persists relevant cache files under `user://`
6. later scenes read from `GameState` first and refresh from API only when needed

Bootstrap now includes the startup copy of settings-center fields:

- `displayName`
- `playerName`
- `avatarId`
- `bio`
- `birthday`
- `genderType`
- `region`
- `linkedProviders`

### 7.2 Settings Center Flow

1. user clicks the top-left profile block in `BattleScene`
2. `ConfigScene` opens and renders from local `GameState.player_data`
3. `ConfigScene` calls `ApiClient.get_profile_me(...)`
4. response flows through `GameState.apply_profile_response(...)`
5. save uses `ApiClient.update_profile_me(...)`
6. success emits `player_profile_changed` and refreshes the home HUD

### 7.3 Redeem Code Flow

1. user enters a code in `ConfigScene`
2. `ApiClient.redeem_code(...)` calls backend
3. success returns `walletSnapshot` and `grantedRewards`
4. `GameState.apply_wallet_snapshot(...)` updates resources
5. `player_wallet_changed` refreshes the home resource UI

### 7.4 Local Audio Settings Flow

1. `ClientSettings` loads `user://client_settings.json`
2. `UiAudio.ensure_audio_buses()` guarantees `Master`, `BGM`, `SFX`
3. slider / mute changes call `ClientSettings.set_volume(...)` or `set_muted(...)`
4. `UiAudio.apply_settings(...)` applies changes immediately

### 7.5 Lineup Save Flow

1. `LineupScene` edits only local draft state
2. save calls `ApiClient.replace_team(...)`
3. response updates `GameState.teams_data`
4. cache writes back to `user://config/teams.json`
5. saving the `Boss` lineup re-applies the home battle team immediately

---

## 8. Navigation Map

Current high-level navigation:

- `StartScene` -> `HomeShellScene`
- `HomeShellScene` keeps `BattleScene` mounted in the background
- `BattleScene` top-left profile block opens `ConfigScene`
- `BattleScene` bottom nav opens home overlays through `SceneNavigator`:
  - `ScooperScene`
  - `LineupScene`
  - `EnhanceScene`
  - `ActivityScene`
  - `ShopScene`
  - `MailScene`
- `ActivityScene` can open deeper activity routes such as:
  - `DungeonScene`
  - `ArenaScene`
- `ShopScene` can open `GachaScene`
- battle-specific routes also open:
  - `ArenaBattleScene`
  - `DungeonBattleScene`

`SceneNavigator` coordinates home overlays, while dedicated battle / activity routes still change scenes directly when leaving the home shell.

---

## 9. Feature Ownership Map

### 9.1 Auth / Startup

- `scripts/StartScene.gd`
- `scripts/ApiClient.gd`
- `scripts/gamestate/GameState.gd`
- `config/runtime_config*.json`

### 9.2 Core Battle / Home HUD

- `scripts/battle/battle_scene.gd`
- `scripts/battle/battle_manager.gd`
- `scripts/battle/battle_simulator.gd`
- `scripts/ui/asset_resolver.gd`
- `scripts/ui/UiAudio.gd`

Current notes:

- `BattleScene` is the persistent home battle surface mounted under `HomeShellScene`.
- It now owns the top-left settings entry and home BGM playback.
- It listens to `player_profile_changed` and `player_wallet_changed`.
- It also owns the home scooper shortcut HUD, including `HomeScoopButtonTemplate.tscn`, scoop animation playback, and the auto-scoop toggle state.

### 9.3 Settings Center

- `scripts/configs/ConfigScene.gd`
- `scripts/ApiClient.gd`
- `scripts/gamestate/GameState.gd`
- `scripts/gamestate/ClientSettings.gd`
- `scripts/ui/UiAudio.gd`
- related docs:
  - `docs/gdd/08_ui.md`
  - `docs/gdd/11_account.md`
  - `docs/gdd/15_config_data_architecture.md`

Current notes:

- `ConfigScene` is now the real settings center.
- It owns profile editing, account / linked-provider display, redeem code UI, and local audio settings.
- OAuth is currently status-only: `Google` and `Apple` cards are visible but disabled when unbound.

### 9.4 Team Lineup

- `scripts/lineup/LineupScene.gd`
- `scripts/lineup/LineupConstants.gd`
- `scripts/gamestate/GameState.gd`
- related doc: `docs/gdd/15_config_data_architecture.md`

Current notes:

- This is the old team-config feature moved out of `ConfigScene`.
- It keeps per-tab draft state for `boss`, `dungeon`, `arena_attack`, and `arena_defense`.
- Team members remain slot-based and are not compacted automatically.

### 9.5 Enhance

- `scripts/enhance/EnhanceScene.gd`
- `scripts/enhance/EnhanceSceneUI.gd`
- `scripts/enhance/EnhanceSceneRefresh.gd`
- `scripts/enhance/EnhanceSceneActions.gd`

### 9.6 Dungeon

- `scripts/dungeon/DungeonScene.gd`
- `scripts/dungeon/DungeonSceneUI.gd`
- `scripts/dungeon/DungeonSceneActions.gd`
- `scripts/gamestate/GameState.gd`

### 9.7 Arena

- `scripts/arenaScene/ArenaScene.gd`
- `scripts/arenaScene/arena_scene_helpers.gd`
- `scripts/battle/arena_battle_scene.gd`
- `scripts/gamestate/GameState.gd`

### 9.8 Scooper

- `scripts/ScooperScene.gd`
- `scripts/scooper/`
- `scripts/ApiClient.gd`
- `scripts/gamestate/GameState.gd`

### 9.9 Gacha / Shop

- `scripts/gacha/GachaScene.gd`
- `scripts/gacha/GachaResultPanel.gd`
- `scripts/shop/ShopScene.gd`
- `scripts/shop/ShopTrapCageView.gd`
- `scripts/shop/ShopBundleView.gd`
- `scripts/gamestate/GameState.gd`

---

## 10. Current Frontend Conventions

### 10.1 Build UI in Script First

Before assuming a `.tscn` contains the UI tree, inspect the paired `.gd` file.

### 10.2 Prefer Existing Scene Boundaries

Follow the project’s current splits instead of inventing a new pattern for one feature.

Examples:

- `ConfigScene` owns settings-center logic
- `LineupScene` owns lineup draft logic
- `EnhanceScene` is already split into UI / refresh / actions
- `DungeonScene` is already split into UI / actions

### 10.3 Use Autoloads For Shared Services

Shared dependencies should go through:

- `GameState`
- `ApiClient`
- `DialogManager`
- `ToastManager`
- `UiAudio`
- `ClientSettings`

### 10.4 Persist Through Shared Owners

- API-backed cross-scene state -> `GameState`
- device-local audio settings -> `ClientSettings`

### 10.5 UI Component Rules

Do not re-implement shared UI styling inline.

- Buttons -> `UiPalette.apply_button_kind(...)`
- Panels / cards -> `OverlaySceneChrome.make_panel_style(...)` or `make_card_panel(...)`
- Non-blocking feedback -> `ToastManager`
- Blocking choices / acknowledgements -> `DialogManager`

---

## 11. Safe Change Guide For AI Agents

### 11.1 If You Need To Change API-Driven UI

Check in this order:

1. scene shell file
2. related helper / action file
3. `ApiClient.gd`
4. `GameState.gd` or `ClientSettings.gd`
5. related `docs/gdd/*.md`

### 11.2 If You Need To Add A New Persisted API Feature

Expected work usually includes:

1. add `ApiClient` convenience method
2. add `GameState` update method and state fields
3. add cache save / load if needed
4. update the scene to read from shared state
5. update architecture docs

### 11.3 If You Need To Add A New Device-Local Setting

Expected work usually includes:

1. add key to `ClientSettings.DEFAULT_SETTINGS`
2. normalize / save / load it in `ClientSettings`
3. apply it through the relevant runtime subsystem
4. expose it in the correct settings-center section
5. update docs

---

## 12. Paths AI Should Inspect First

When orientation is needed, inspect these files first:

- `project.godot`
- `AGENTS.md`
- `scripts/StartScene.gd`
- `scripts/ApiClient.gd`
- `scripts/gamestate/GameState.gd`
- `scripts/gamestate/ClientSettings.gd`
- `scripts/ui/UiAudio.gd`
- `scripts/data/static_game_data.gd`

Then inspect the feature-specific scene and helper folder.

---

## 13. Non-Goals And Things To Avoid

- Do not assume `.tscn` files fully describe the UI
- Do not store persistent runtime data in `res://`
- Do not bypass `ApiClient` with ad hoc per-scene HTTP code
- Do not duplicate state already owned by `GameState` or `ClientSettings`
- Do not reintroduce the old assumption that `ConfigScene` means team setup
- Do not rewrite `StartScene` visual identity unless explicitly requested

---

## 14. Related Documents

- `docs/gdd/08_ui.md`
- `docs/gdd/11_account.md`
- `docs/gdd/14_scooper_data_architecture.md`
- `docs/gdd/15_config_data_architecture.md`
- `docs/gdd/16_dungeon_data_architecture.md`
- `docs/gdd/17_arena_data_architecture.md`
- `docs/ui_component_spec.md`

Update this document whenever the client introduces a new durable subsystem, a new singleton, or a materially different data flow pattern.
