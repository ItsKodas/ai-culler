# AI Culler — Arma 3 Performance Mod

A two-part mod that tackles Arma 3 performance from both ends: a server-side AI simulation culler and a client-side model renderer. Designed for large milsim ops with 60+ players and high AI counts.

Workshop: https://steamcommunity.com/sharedfiles/filedetails/?id=3744994173

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
| Max AI | `AIC_maxActiveAI` | 200 |
| Dist BLUFOR | `AIC_distBlufor` | 2000m |
| Dist OPFOR | `AIC_distOpfor` | 2000m |
| Dist Indep | `AIC_distIndependent` | 2000m |
| Dist Civ | `AIC_distCivilian` | 500m |
| Interval(s) | `AIC_checkInterval` | 5s |
| Min Radius | `AIC_minActiveRadius` | 200m |
| Combat Rad | `AIC_combatRadius` | 400m |
| Debug | `AIC_debug` | OFF |

#### Pre-op (edit defaults)

Edit `@ai_culler/addons/aic_main/functions/fn_preInit.sqf` and rebuild the PBO:

| Variable | Default | Description |
|---|---|---|
| `AIC_maxActiveAI` | 200 | Hard cap on simultaneously active AI |
| `AIC_distBlufor` | 2000m | Cull distance for BLUFOR (west) |
| `AIC_distOpfor` | 2000m | Cull distance for OPFOR (east) |
| `AIC_distIndependent` | 2000m | Cull distance for Independent |
| `AIC_distCivilian` | 500m | Cull distance for Civilians |
| `AIC_checkInterval` | 5s | How often the culler runs — also controls load spreading (see below) |
| `AIC_minActiveRadius` | 200m | Units within this radius are always active (no LOS check) |
| `AIC_combatRadius` | 400m | Radius used to detect AI vs AI combat engagement |
| `AIC_debug` | false | RPT logging — enable for diagnostics only |

#### Performance tuning with `AIC_checkInterval`

The classification loop (raycasts + proximity checks for every AI unit) runs in chunks of 25 units, yielding between each chunk so the server thread is never blocked for the full duration. The total spread targets **40% of `AIC_checkInterval`** — at the 5s default, the work is distributed across ~2 seconds with the remaining 3 seconds idle.

If the server is under heavy load, increasing the interval is the primary tuning lever:

| `AIC_checkInterval` | Work spread | Idle time | Activation latency |
|---|---|---|---|
| 5s (default) | ~2s | ~3s | up to 5s |
| 8s | ~3.2s | ~4.8s | up to 8s |
| 10s | ~4s | ~6s | up to 10s |

Activation latency (how long before a newly relevant unit gets enabled) is the only gameplay trade-off. For most milsim ops, 8–10s is imperceptible since engagements develop over minutes. `AIC_checkInterval` is adjustable live from the Zeus settings panel — no restart required.

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

| Field | Variable | Description |
|---|---|---|
| Client Renderer | `AIC_clientEnabled` | Toggle the renderer on or off |
| Radius | `AIC_clientRadius` | Max distance to check AI for occlusion — auto-set from ACE view distance if ACE3 is loaded, otherwise 2000m. Can be overridden here |
| Safe Radius | `AIC_clientSafeRadius` | AI within this distance are always rendered to prevent pop-in |
| Debug HUD | `AIC_clientDebug` | Enables the on-screen overlay showing live renderer stats |

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

Each client runs a LOS check between the player's eye position and every living AI infantry unit within `AIC_clientRadius`. If a unit is fully occluded — hidden behind terrain or solid objects — its model is hidden via `hideObject`. It is shown again the moment LOS is restored.

The check is intentionally permissive:
- **Trees and bushes are ignored** — a unit behind a tree is still hidden, but the tree itself does not count as occlusion
- **Terrain is checked first** (cheap raycast), then solid objects (building walls, vehicles, rocks)
- **Safe radius** — units within `AIC_clientSafeRadius` are always rendered regardless of LOS, preventing pop-in as AI close distance
- **ADS cone** — when the player is holding RMB (precision aim) or looking through a weapon optic, AI within ~30° of the camera's aim direction are force-rendered even if occluded. This prevents units from vanishing as you peek around corners to engage them
- **Zeus camera** — while the Zeus interface is open, no units are hidden. All previously hidden units are restored immediately on entry so the Zeus player sees the full battlefield

`hideObject` is client-local — it affects only the machine running the check and does not change AI state or hitboxes for any other player.

#### Adaptive cadence

The renderer does not run on a fixed interval. It uses Arma's built-in 16-frame `diag_fps` rolling average to continuously adjust its own tick rate via `linearConversion`:

| FPS | Tick interval |
|---|---|
| 45+ | 0.2s (fastest) |
| 15 | 1.0s (slowest) |
| Between | Linear ramp |

Under load the renderer backs off automatically, reducing its own contribution to frame time. When performance recovers it tightens back up without any manual adjustment.

#### Budgeted LOS sweep

Rather than checking every AI candidate in a single tick, the LOS work is spread across multiple ticks in slices. Each slice processes `ceil(poolSize / AIC_clientSweepTicks)` units (default: targets completion in ~4 ticks). This eliminates single-tick spikes when many AI are in radius — frame cost is capped and predictable regardless of AI count.

If FPS drops below `AIC_clientFpsFloor`, the slice size is throttled down to `AIC_clientBudgetMin` to protect frame time at the cost of slower sweep completion. Both limits are clamped to `AIC_clientBudgetMax` (default 40) as a spike guard.

### Why this helps

Arma 3's renderer draws everything within the camera frustum (the cone in front of you). It has no robust occlusion culling — a wall of buildings does not stop the GPU from processing the AI behind them. The `hideObject` call removes those models from the render pipeline entirely, which produces a measurable FPS improvement when looking toward large AI forces behind cover.

This is architecturally different from mods like A3PE (Arma 3 Performance Extension), which also uses LOS but runs server-side — causing its own CPU overhead that can reduce performance on loaded servers. `aic_client` distributes the work across all connected clients, adding no server load.

### Debug HUD

When **Debug HUD** is enabled from the Zeus Client Renderer panel, a small yellow overlay appears in the bottom-left corner of every client's screen:

```
CR:47v 112h [ADS] | fps45 int0.20 bud25 | sweep25/100
```

| Field | Description |
|---|---|
| `47v 112h` | Visible and hidden AI counts |
| `[ADS]` | ADS cone override is active (RMB held or optic view open) |
| `fps45` | Smoothed FPS average driving the cadence |
| `int0.20` | Current tick interval in seconds |
| `bud25` | Current LOS slice size (raycasts this tick) |
| `sweep25/100` | Cursor position in the current sweep queue |

This updates every renderer tick and disappears automatically when the renderer or debug mode is turned off.

### Default settings

Edit `@ai_culler/addons/aic_client/functions/fn_clientPreInit.sqf` and rebuild the PBO to change defaults:

| Variable | Default | Description |
|---|---|---|
| `AIC_clientEnabled` | true | Enable the renderer on load |
| `AIC_clientSafeRadius` | 75m | Always-render radius around the player |
| `AIC_clientDebug` | false | Show debug HUD on load |

**Radius** — `AIC_clientRadius` is no longer a static default. If ACE3 is loaded it is read from `ace_viewdistance_viewDistanceOnFoot` at mission start and kept in sync every 30 seconds. Without ACE3 it falls back to 2000m. It can still be overridden live from the Zeus Client Renderer panel.

**Adaptive cadence knobs:**

| Variable | Default | Description |
|---|---|---|
| `AIC_clientIntervalMin` | 0.2s | Fastest tick rate, used at or above `FpsTarget` |
| `AIC_clientIntervalMax` | 1.0s | Slowest tick rate, used at or below `FpsFloor` |
| `AIC_clientFpsTarget` | 45 | FPS at which the fastest cadence is used |
| `AIC_clientFpsFloor` | 15 | FPS at which the slowest cadence and minimum budget kick in |

**Budget knobs:**

| Variable | Default | Description |
|---|---|---|
| `AIC_clientSweepTicks` | 3 | Target number of ticks to complete a full LOS sweep — primary tuning lever |
| `AIC_clientBudgetMin` | 10 | Minimum LOS checks per tick when FPS is below `FpsFloor` |
| `AIC_clientBudgetMax` | 60 | Hard cap on LOS checks per tick regardless of pool size |

---

## Compatibility

- ✅ CBA_A3 (required by `aic_client`)
- ✅ LAMBS Danger (AI behaviour state preserved on enable/disable — no longer overwritten)
- ✅ Headless Clients
- ✅ Civilian Presence Module
- ✅ Zeus / Curator
- ✅ ACE3 (view distance auto-sync when loaded)
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
            ├── fn_clientPreInit.sqf       # Defaults + initialises renderer at mission start
            ├── fn_clientLoop.sqf          # Per-tick LOS check and hideObject calls
            ├── fn_clientZeusHooks.sqf     # Client Renderer panel lifecycle in Zeus
            └── fn_createClientPanel.sqf   # Builds the Zeus Client Renderer UI controls
```

---

## Changelog

### v3.3.0
- LOS check now evaluated against **all** connected players — a unit is kept active if any player has line of sight, not just the nearest. Previously a unit could be incorrectly culled while visible to a second player standing elsewhere
- `CAManBase` replaces `Man` in all unit filters — ensures full coverage of modded infantry that inherit from `CAManBase` but not `Man`
- `AIC_zeusProtected` variable tag added to the protection flag (was untagged `zeusProtected`) — prevents potential conflicts with other mods or mission scripts using the same name
- `disableAI "ALL"` / `enableAI "ALL"` removed — simulation state is now saved before disabling and restored on re-enable, preserving AI behaviour modifications set by other mods (LAMBS, etc.)
- Zeus stats (`AIC_serverFPS`, status window data) now sent only to active curator clients via `publicVariableClient` instead of broadcast to all players — reduces unnecessary network traffic
- Label updates (unit name prefixes) now sent as a single batched `remoteExec` per tick covering only units whose state changed — previously one network call per unit
- Toggle protection now uses smart group logic: protects all selected units if any are unprotected; only unprotects when all are already protected — more predictable with mixed selections
- Client renderer now runs inline at `postInit` time instead of spawning a thread to wait for player initialisation
- Client renderer FPS input simplified to Arma's native 16-frame `diag_fps` rolling average — the previous EMA was double-smoothing an already-averaged value
- Fixed: nil guard added to Zeus FPS display — prevents a brief display error before the server sends its first `AIC_serverFPS` update
- Default `AIC_distIndependent` corrected to 2000m (was 1000m, an unintentional asymmetry versus BLUFOR/OPFOR defaults)
- Default `AIC_debug` corrected to `false` (was incorrectly left as `true` in the released mod)

### v3.2.0
- Client renderer tick rate is now adaptive — a 10-frame FPS EMA drives a `linearConversion` ramp between 0.2s (45fps+) and 1.0s (15fps), reducing renderer overhead automatically under load
- LOS work is now spread across multiple ticks in budgeted slices instead of evaluating all candidates in one pass — eliminates single-tick spikes on high AI count missions
- Slice size scales dynamically with pool size (`ceil(queueSize / AIC_clientSweepTicks)`), targeting sweep completion in ~4 ticks; clamped to `AIC_clientBudgetMax` (40) as a spike guard
- FPS floor guard (`AIC_clientFpsFloor = 15`) throttles the slice size to `AIC_clientBudgetMin` (10) when frames are genuinely collapsing, protecting frame time at the cost of slower sweep completion
- `AIC_clientRadius` is now auto-detected from ACE view distance on foot at mission start and polled every 30 seconds (real-time) to track mid-mission changes; falls back to 2000m without ACE3
- Fixed: units hidden early in a multi-tick sweep are now revealed immediately if they enter the safe radius or leave the candidate pool — previously they lingered invisible until the sweep finished
- Fixed: disabling the renderer or entering Zeus while a sweep was in progress left mid-sweep hidden units permanently invisible — both branches now reveal all hidden units before clearing state
- Debug HUD updated to show live FPS average, current interval, current budget, and sweep progress alongside visible/hidden counts
- Added `cba_main` as a required addon for `aic_client`

### v3.1.2
- Classification loop now yields between every 25-unit chunk instead of running synchronously, eliminating per-tick FPS spikes on the server
- Yield time is computed dynamically: total spread targets ~40% of `AIC_checkInterval` (~2s at default 5s), scaling automatically as AI count and interval change
- `AIC_checkInterval` is now the primary performance lever — increasing it gives the server more breathing room without any other config changes; adjustable live from the Zeus settings panel

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
