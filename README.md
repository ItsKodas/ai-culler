# AI Culler — Arma 3 Performance Mod

A two-part mod that tackles Arma 3 performance from both ends: a server-side AI simulation culler and a client-side model renderer. Designed for large milsim ops with 60+ players and high AI counts.

---

## The Problem

Arma 3 has two distinct performance bottlenecks at scale:

- **Server**: simulates every AI unit simultaneously on a fixed cycle — beyond ~150 units this causes periodic frame spikes even with LAMBS and Headless Clients
- **Client**: renders everything within the camera frustum regardless of whether it's behind a building or hill — looking toward a large AI force drops FPS significantly even when nothing is visible on screen

## The Solution

AI Culler addresses both problems independently:

| Component | Runs On | What It Does |
|---|---|---|
| `aic_main` | Server + Zeus clients | Caps active AI simulation, prioritises units by proximity and LOS |
| `aic_client` | All player clients | Hides AI models that are fully occluded from the player's view |

Both addons are packed into `@ai_culler` — everyone loads the same mod and the right code runs based on machine type.

---

## Installation

1. Copy the `@ai_culler` folder into your Arma 3 directory
2. Add `-mod=@ai_culler` to **all** launch parameters — server, Zeus clients, and player clients
3. No mission changes required — no `init.sqf` entry needed

---

## Server-Side Culler (`aic_main`)

### How it works

Each unit is classified into one of five states every tick:

| State | Condition | Simulation |
|---|---|---|
| **Protected** | Marked via right-click or placement flag | Always active |
| **Override** | Zeus has assigned waypoints to the group | Always active |
| **Active (LOS)** | In range and player has line of sight | Always active |
| **Active (No-LOS)** | In range but no LOS | Active only if under cap |
| **Culled** | Beyond faction cull distance | Always disabled |

When a group is in **Override** or any unit in range is engaged in **AI vs AI combat**, simulation is forced on regardless of player proximity or the active unit cap. Vehicles are never culled.

### Configuration

#### Mid-op (Zeus settings panel)

Open Zeus → click **Settings** in the AIC status window to adjust values live. Click **Apply** to push changes to the server immediately.

| Field | Variable | Default |
|---|---|---|
| Max AI | `AIC_maxActiveAI` | 100 |
| Dist BLUFOR | `AIC_distBlufor` | 2000m |
| Dist OPFOR | `AIC_distOpfor` | 2000m |
| Dist Indep | `AIC_distIndependent` | 1000m |
| Dist Civ | `AIC_distCivilian` | 500m |
| Interval(s) | `AIC_checkInterval` | 5s |
| Min Radius | `AIC_minActiveRadius` | 200m |
| Combat Rad | `AIC_combatRadius` | 400m |
| Debug | `AIC_debug` | ON |

#### Pre-op (edit defaults)

Edit `@ai_culler/addons/aic_main/functions/fn_preInit.sqf` and rebuild the PBO:

| Variable | Default | Description |
|---|---|---|
| `AIC_maxActiveAI` | 100 | Hard cap on simultaneously active AI |
| `AIC_distBlufor` | 2000m | Cull distance for BLUFOR (west) |
| `AIC_distOpfor` | 2000m | Cull distance for OPFOR (east) |
| `AIC_distIndependent` | 1000m | Cull distance for Independent |
| `AIC_distCivilian` | 500m | Cull distance for Civilians |
| `AIC_checkInterval` | 5s | How often the culler runs |
| `AIC_minActiveRadius` | 200m | Units within this radius are always active (no LOS check) |
| `AIC_combatRadius` | 400m | Radius used to detect AI vs AI combat engagement |
| `AIC_debug` | true | RPT logging — set to `false` for live ops |

---

## Zeus Interface

### Status window

Opens automatically when Zeus is active. The left column shows live culling stats; the right column shows server-wide counts and FPS. Both columns update on every tick — even when the culler is disabled.

| Left column | Description |
|---|---|
| Active | Currently simulating units / cap |
| LOS | Units active because a player has line of sight |
| No-LOS | Units active due to proximity but no LOS |
| Culled | Units with simulation disabled |
| Protected | Units excluded from culling entirely |
| Override | Units active because Zeus assigned their group a waypoint |

| Right column | Description |
|---|---|
| Total AI | All living AI across the server |
| Srv FPS | Server FPS at last tick |
| Clt FPS | Zeus client FPS (local to the Zeus player) |

Click **▲/▼** to collapse or expand. Press **Backspace** to hide/show the panel without affecting Zeus's own HUD.

### Buttons

- **Disable Culler / Enable Culler** — pauses and resumes culling. All previously culled AI are re-enabled when disabled. Stats continue to update.
- **Settings** — expands an inline panel to adjust all config values live. Click **Apply** to push changes to the server.

### Client Renderer panel

Sits to the right of the main AIC panel. Controls the client-side model hider for all connected players simultaneously.

| Field | Variable | Default | Description |
|---|---|---|---|
| Client Renderer | `AIC_clientEnabled` | ON | Toggle the renderer on or off |
| Radius | `AIC_clientRadius` | 1500m | Max distance to check AI for occlusion — set to match your server's object view distance |
| Safe Radius | `AIC_clientSafeRadius` | 75m | AI within this distance are always rendered to prevent pop-in |
| Interval(s) | `AIC_clientInterval` | 0.3s | How often each client runs the LOS check |
| Debug HUD | `AIC_clientDebug` | OFF | Enables a small on-screen overlay showing rendered vs hidden AI counts |

Clicking **Apply** broadcasts all values to every connected client via `publicVariable`.

Press **Backspace** to hide/show the Client Renderer panel alongside the main panel.

### Zeus waypoint Override

When Zeus assigns a move order to a group, AI Culler detects the new waypoint within one poll interval (default 5s) and activates the group regardless of distance from players. The Override label appears on each unit's 3D floating label and increments the Override counter in the status window.

Once the group completes all Zeus-assigned waypoints, Override clears automatically and normal culling resumes. Override does not fire during active combat — Arma 3 generates its own combat waypoints (MOVE/SAD) internally, so the combat guard prevents those from being mistaken for Zeus orders.

### AI vs AI combat activation

Units in proximity to enemy AI (within `AIC_combatRadius`) are activated regardless of player distance or the active unit cap. This prevents distant firefights between AI factions from freezing mid-engagement. Once neither side has enemy contact within range, normal culling resumes on the next tick.

### 3D floating labels

While Zeus is open, a floating label is drawn above each managed unit visible within 800m of the Zeus camera:

| Label | Colour | Meaning |
|---|---|---|
| `[Protected]` | Green | Excluded from culling |
| `[Culled]` | Orange | Simulation disabled |
| `[Override]` | Blue | Active due to Zeus waypoint |

### ZEN context menu

If **ZEN Enhanced Zeus** is loaded, a **Toggle Culler Protection** option appears in the right-click context menu for any AI infantry.

---

## Client-Side Renderer (`aic_client`)

### How it works

Each tick, every client runs a LOS check between the player's eye position and every living AI infantry unit within `AIC_clientRadius`. If a unit is fully occluded — hidden behind terrain or solid objects — its model is hidden via `hideObject`. It is shown again the moment LOS is restored.

The check is intentionally permissive:
- **Trees and bushes are ignored** — a unit behind a tree is still hidden, but the tree itself does not count as occlusion
- **Terrain is checked first** (cheap raycast), then solid objects (building walls, vehicles, rocks)
- **Safe radius** — units within `AIC_clientSafeRadius` are always rendered regardless of LOS, preventing pop-in as AI close distance
- **ADS cone** — when the player is holding RMB (precision aim) or looking through a weapon optic, AI within ~30° of the camera's aim direction are force-rendered even if occluded. This prevents units from vanishing as you peek around corners to engage them
- **Zeus camera** — while the Zeus interface is open, no units are hidden. All previously hidden units are restored immediately on entry so the Zeus player sees the full battlefield

`hideObject` is client-local — it affects only the machine running the check and does not change AI state or hitboxes for any other player.

### Why this helps

Arma 3's renderer draws everything within the camera frustum (the cone in front of you). It has no robust occlusion culling — a wall of buildings does not stop the GPU from processing the AI behind them. The `hideObject` call removes those models from the render pipeline entirely, which produces a measurable FPS improvement when looking toward large AI forces behind cover.

This is architecturally different from mods like A3PE (Arma 3 Performance Extension), which also uses LOS but runs server-side — causing its own CPU overhead that can reduce performance on loaded servers. `aic_client` distributes the work across all connected clients, adding no server load.

### Debug HUD

When **Debug HUD** is enabled from the Zeus Client Renderer panel, a small yellow overlay appears in the bottom-left corner of every client's screen:

```
CR: 47 visible | 112 hidden [ADS]
```

`[ADS]` appears when the cone override is active (RMB held or optic view open). This updates every renderer tick and disappears automatically when the renderer or debug mode is turned off.

### Default settings

Edit `@ai_culler/addons/aic_client/functions/fn_clientPreInit.sqf` and rebuild the PBO to change defaults:

| Variable | Default | Description |
|---|---|---|
| `AIC_clientEnabled` | true | Enable the renderer on load |
| `AIC_clientRadius` | 1500m | Max LOS check radius — match your server's object view distance |
| `AIC_clientSafeRadius` | 75m | Always-render radius around the player |
| `AIC_clientInterval` | 0.3s | Seconds between each LOS pass |
| `AIC_clientDebug` | false | Show debug HUD on load |

---

## Compatibility

- ✅ LAMBS Danger
- ✅ Headless Clients
- ✅ Civilian Presence Module
- ✅ Zeus / Curator
- ✅ ACE3
- ✅ ZEN Enhanced Zeus (context menu integration)
- ⚠️ Vcom AI — not tested, may conflict

---

## Project Structure

```
@ai_culler/
└── addons/
    ├── aic_main/                          # Server-side culler + Zeus UI
    │   ├── config.cpp
    │   └── functions/
    │       ├── fn_preInit.sqf             # Settings — edit to tune defaults
    │       ├── fn_postInit.sqf            # Server loop + Zeus hook branching
    │       ├── fn_mainLoop.sqf            # Main culler loop (runs on server each tick)
    │       ├── fn_getCullDist.sqf         # Returns per-faction cull distance
    │       ├── fn_enableUnit.sqf          # Re-enables simulation on a unit
    │       ├── fn_disableUnit.sqf         # Disables simulation on a unit
    │       ├── fn_broadcastStats.sqf      # Sends stats to Zeus clients each tick
    │       ├── fn_updateStatusWindow.sqf  # Updates stat rows in the Zeus UI
    │       ├── fn_updateUnitLabel.sqf     # Updates the name prefix shown in Zeus
    │       ├── fn_toggleProtection.sqf    # Right-click toggle handler
    │       ├── fn_setCullerEnabled.sqf    # Server-side culler on/off
    │       ├── fn_applySettings.sqf       # Server-side settings update (mid-op)
    │       ├── fn_initZeusHooks.sqf       # Status window lifecycle + 3D labels
    │       └── fn_createStatusWindow.sqf  # Builds the Zeus UI controls
    └── aic_client/                        # Client-side model renderer
        ├── config.cpp
        └── functions/
            ├── fn_clientPreInit.sqf       # Defaults + spawns loop on mission start
            ├── fn_clientLoop.sqf          # Per-tick LOS check and hideObject calls
            ├── fn_clientZeusHooks.sqf     # Client Renderer panel lifecycle in Zeus
            └── fn_createClientPanel.sqf   # Builds the Zeus Client Renderer UI controls
```

---

## Changelog

### v3.1.1
- Added ADS cone override — units within ~30° of the player's aim direction are force-rendered while holding RMB (no optic) or while looking through a weapon optic, preventing occluded units from vanishing during peek-around-corner engagements
- Added Zeus camera bypass — while the Zeus interface is open, all previously hidden units are immediately restored and culling is suspended so the Zeus player sees the full battlefield
- Debug HUD now displays `[ADS]` when the cone override is active
- Fixed ADS detection using invalid `inputAction` names (`"Zoom"`, `"OpticsCursor"`) that always returned 0 — replaced with `"zoomTemp"` (hold RMB precision aim) and `cameraView == "GUNNER"` (weapon optic active)

### v3.1.0
- Added `aic_client` addon — client-side LOS model hider that hides occluded AI infantry via `hideObject`, reducing client FPS impact from large AI forces
- Trees and bushes are excluded from occlusion checks — only solid structures block render
- Safe radius (default 75m) always renders nearby AI to prevent pop-in
- Added Zeus Client Renderer panel — sits to the right of the main AIC panel, lets Zeus hot-change radius, safe radius, interval, enable toggle, and debug HUD for all clients via `publicVariable`
- Added per-client debug HUD overlay showing live rendered vs hidden AI counts
- Added right column to the Zeus status window: Total AI, Server FPS, and Client FPS
- Total AI and FPS stats now update live even when the culler is disabled
- All clients load `-mod=@ai_culler` — machine type determines which code runs

### v3.0.0
- Added Zeus waypoint Override — AI groups activate automatically when Zeus assigns them a move order, regardless of player proximity. Override clears when all Zeus waypoints are completed
- Added AI vs AI combat detection — units engaging enemy AI within `AIC_combatRadius` are always activated regardless of distance or cap
- Added `AIC_distBlufor` — BLUFOR now has its own cull distance separate from OPFOR
- Added `AIC_minActiveRadius` — units within this fixed radius of a player are always active (no LOS raycast needed)
- Added `AIC_combatRadius` — configurable radius for AI vs AI combat detection
- Expanded Settings panel to expose all 9 config variables including Debug toggle, BLUFOR dist, Min Radius, and Combat Radius
- Added 3D floating labels above units visible to the Zeus camera (Protected / Culled / Override)
- Added Override stat row to the Zeus status window
- Fixed Backspace panel hide/show — replaced unreliable `ctrlVisible` check with explicit state tracking
- Fixed false Override triggers during AI combat — combat guard prevents Arma's auto-generated combat waypoints from being mistaken for Zeus orders
- Updated defaults: maxActiveAI 100, distOpfor/Blufor 2000m, distIndependent 1000m, distCivilian 500m

### v2.1.0
- Added inline Settings panel to Zeus status window — adjust Max AI, cull distances, and check interval mid-op without rebuilding the PBO
- Settings changes sync to all Zeus clients via `publicVariable`

### v2.0.0
- Converted from mission script to standalone mod — no mission `init.sqf` required
- Vehicles permanently excluded from culling
- Zeus auto-protection removed — all Zeus-placed units enter the culler pool by default
- Added "Toggle Culler Protection" Zeus right-click context action
- Added collapsible in-Zeus status window with live stats
- Added "Disable/Enable Culler" toggle button in the status window
- Settings and variables renamed to `AIC_*` prefix

### v1.0.0
- Initial release as mission script
