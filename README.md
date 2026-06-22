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

When a group is in **Override** or any unit in range is engaged in **AI vs AI combat**, simulation is forced on regardless of player proximity or the active unit cap. Vehicles are never culled. Units currently being remote controlled by a Zeus player and units in free-fall or under a parachute are also excluded from the managed pool and their simulation is never disabled.

### Configuration

#### Mid-op (Zeus settings panel)

Open Zeus → click **Settings** in the AIC status window to adjust values live. Click **Apply** to push changes to the server immediately.

| Field | Variable | Default |
|---|---|---|
| Max AI | `AIC_maxActiveAI` | 150 |
| Dist BLUFOR | `AIC_distBlufor` | 2000m |
| Dist OPFOR | `AIC_distOpfor` | 2000m |
| Dist Indep | `AIC_distIndependent` | 2000m |
| Dist Civ | `AIC_distCivilian` | 500m |
| Interval(s) | `AIC_checkInterval` | 5s |
| Min Radius | `AIC_minActiveRadius` | 200m |
| Combat Rad | `AIC_combatRadius` | 400m |
| Debug | `AIC_debug` | OFF |

#### Pre-op (Addon Options — requires CBA_A3)

Open **Configure → Addon Options → AI Culler** before launching a mission. All values are saved per-user and applied automatically at mission start. The server's values are broadcast to all clients when `isGlobal` settings are used.

| Setting | Default | Description |
|---|---|---|
| Enable Culler on Start | true | Whether the culler is active when the mission begins |
| Max Active AI | 150 | Hard cap on simultaneously active AI |
| BLUFOR Cull Distance | 2000m | Cull distance for BLUFOR (west) |
| OPFOR Cull Distance | 2000m | Cull distance for OPFOR (east) |
| Independent Cull Distance | 2000m | Cull distance for Independent |
| Civilian Cull Distance | 500m | Cull distance for Civilians |
| Check Interval | 5s | How often the culler runs — also controls load spreading (see below) |
| Min Active Radius | 200m | Units within this radius are always active (no LOS check) |
| Combat Detection Radius | 400m | Radius used to detect AI vs AI combat engagement |
| Debug Logging | false | RPT logging — enable for diagnostics only |
| Show Enable/Disable Notifications | false | Show a notification to all players when the culler is enabled or disabled |

#### Pre-op (without CBA_A3)

Defaults are set in `@ai_culler/addons/aic_main/functions/fn_preInit.sqf` and applied if CBA_A3 is not loaded. Edit and rebuild the PBO to change them.

| Variable | Default | Description |
|---|---|---|
| `AIC_maxActiveAI` | 150 | Hard cap on simultaneously active AI |
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

Opens automatically when Zeus is active. The left column shows live culling stats; the right column shows server-wide counts and FPS. Both columns update on every tick — even when the culler is disabled. The **Active** count is color-coded: green when below cap, yellow at exactly cap, orange up to 2× cap, and flashing red above 2× cap.

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
- **FPS Graph** — opens a floating sparkline showing server FPS over the last 88 seconds. All characters are rendered in the same green; height scales from `_` (lowest) to `#` (highest) relative to the session peak FPS. The title bar shows current, average, minimum, and maximum FPS. Updates every second alongside the FPS display.

### Zeus waypoint Override

When Zeus assigns a move order to a group, AI Culler detects the new waypoint within one poll interval (default 5s) and activates the group regardless of distance from players. The Override label appears on each unit's 3D floating label and increments the Override counter in the status window.

Once the group completes all Zeus-assigned waypoints, Override clears automatically and normal culling resumes. Override does not fire during active combat — Arma 3 generates its own combat waypoints (MOVE/SAD) internally, so the combat guard prevents those from being mistaken for Zeus orders.

### AI vs AI combat activation

Units in proximity to enemy AI (within `AIC_combatRadius`) are activated regardless of player distance or the active unit cap. This prevents distant firefights between AI factions from freezing mid-engagement. Once neither side has enemy contact within range, normal culling resumes on the next tick.

### 3D floating labels

While Zeus is open, a floating label is drawn above each managed unit within `AIC_labelDist` of the Zeus camera (default 800m, configurable in Addon Options):

| Label | Colour | Meaning |
|---|---|---|
| `[Protected]` | Green | Excluded from culling |
| `[Culled]` | Orange | Simulation disabled |
| `[Override]` | Blue | Active due to Zeus waypoint |

### ZEN context menu

If **ZEN Enhanced Zeus** is loaded, a **Toggle Culler Protection** option appears in the right-click context menu for any AI infantry.

### Eden Editor protection attribute

In the Eden Editor, every unit's **Object: States** attribute panel includes a **Protected from Culler** checkbox. Enabling it sets `AIC_zeusProtected` at mission start without any scripting — units flagged this way are excluded from culling for the entire mission. This is equivalent to calling `AIC_fnc_protect` from a trigger or init field, but persists across respawns and requires no code.

---

## Client-Side Renderer (`aic_client`)

### Supported configurations

The client renderer works in two scenarios only:

| Scenario | Notes |
|---|---|
| **Singleplayer** | All AI are local; `hideObject` has no network side-effects |
| **Dedicated server MP** | AI are server-local; clients only see remote units |

**Listen server (host-client) is not supported.** When a player also hosts the server, they own AI locally — `hideObject` propagates to all connected clients, breaking visibility for everyone else.

### How it works

Each client runs a two-tier LOS check between the player's eye position and every living AI infantry unit within `AIC_clientRadius`. If a unit is fully occluded it is hidden via `hideObject`. It is shown again the moment LOS is restored.

**Tier 1 — Terrain (always):** `terrainIntersectASL` is a fast terrain-only raycast. If terrain blocks the line, the unit is hidden immediately and tier 2 is skipped. This cheap early-out catches the majority of cases.

**Tier 2 — Surface intersection (within `AIC_clientSurfaceRadius`):** For units closer than 600m that passed the terrain check, `lineIntersectsSurfaces` is run against the View Geometry LOD. This catches buildings, walls, and solid structures. The following hit types are excluded and do not count as occlusion:
- Terrain-baked objects — trees, rocks, and other objects embedded in the terrain return `objNull` from the surface check and are treated as non-blocking
- Objects with `"net"`, `"bag"`, or `"bunker"` in their class name (camo nets, sandbags, open bunker structures)
- Glass and windows — View Geometry does not include transparent surfaces, so units remain visible through them

The check is intentionally permissive:
- **Safe radius** — units within `AIC_clientSafeRadius` (default 150m) are always rendered regardless of LOS, preventing pop-in as AI close distance
- **ADS cone** — when the player is holding RMB (precision aim) or looking through a weapon optic, AI within ~30° of the camera's aim direction are force-rendered even if occluded. This prevents units from vanishing as you peek around corners to engage them
- **Zeus camera** — while the Zeus interface is open, no units are hidden. All previously hidden units are restored as the sweep cycles through them so the Zeus player sees the full battlefield
- **Remote control** — while the local player is remote controlling a unit via Zeus, occlusion is suspended and all units in the sweep queue are shown

`hideObject` is client-local — it affects only the machine running the check and does not change AI state or hitboxes for any other player.

#### Budgeted LOS sweep

Rather than checking every AI candidate in a single tick, the LOS work is spread across multiple ticks in slices. The renderer runs at a fixed 20Hz (every 0.05s) and each tick processes `ceil(poolSize / 60)` units — targeting a full sweep in ~3 seconds. This eliminates single-tick spikes when many AI are in radius; frame cost is capped and predictable regardless of AI count.

### Why this helps

Arma 3's renderer draws everything within the camera frustum (the cone in front of you). It has no robust occlusion culling — a wall of buildings does not stop the GPU from processing the AI behind them. The `hideObject` call removes those models from the render pipeline entirely, which produces a measurable FPS improvement when looking toward large AI forces behind cover.

This is architecturally different from mods like A3PE (Arma 3 Performance Extension), which also uses LOS but runs server-side — causing its own CPU overhead that can reduce performance on loaded servers. `aic_client` distributes the work across all connected clients, adding no server load.

### Debug HUD

When **Debug HUD** is enabled from Addon Options (admin only), a small yellow overlay appears in the bottom-left corner of the screen:

```
CR:47v 112h | fps45 min42 d3 r93% | sweep25/159 batch3 [ADS]
```

| Field | Description |
|---|---|
| `47v 112h` | Visible and hidden AI counts |
| `fps45` | Current FPS (`diag_fps`) |
| `min42` | Minimum FPS this session (`diag_fpsmin`) |
| `d3` | Delta between current and minimum FPS |
| `r93%` | Ratio of min FPS to current FPS — lower means more variance |
| `sweep25/159` | Cursor position / total queue size for the current sweep |
| `batch3` | Number of units processed this tick |
| `[ADS]` | ADS cone override is active (RMB held or optic view open) |

This updates every renderer tick and disappears automatically when the renderer or debug mode is turned off.

### Client renderer Addon Options (requires CBA_A3)

Open **Configure → Addon Options → AI Culler - Client** to set per-client preferences. These are not server-enforced — each player sets their own.

| Setting | Default | Description |
|---|---|---|
| Enable Client Renderer | true | Toggle the LOS hider on or off |
| Show Unit Name Labels | true | Prefix unit names with `[Culled]` / `[Protected]` / `[Override]` when you are Zeus |
| Show 3D Floating Labels | true | Draw floating 3D text above culled/protected/override units in Zeus view |
| 3D Label Draw Distance | 800m | Maximum camera distance at which 3D labels are rendered |
| Safe Radius | 150m | AI within this distance are always rendered regardless of LOS |
| Surface LOS Radius | 600m | Within this distance, full surface intersection is used in addition to terrain LOS. Beyond it, terrain-only. |
| Corpse Hide Radius | 300m | Dead AI beyond this distance are hidden. Set to 0 to always show corpses. |

**Debug HUD** (`AIC_clientDebug`) is server-enforced (`isGlobal = 1`) — the server admin controls it and the value is broadcast to all clients. When enabled it activates the renderer overlay on every connected player simultaneously. It is grouped under the **AI Culler - Client** category but only editable from the server side.

### Radius auto-sync

`AIC_clientRadius` is not a static default. At mission start it is read from the player's view distance and kept in sync every 30 seconds to track mid-mission changes:

- **With ACE3** — reads `ace_viewdistance_viewDistanceOnFoot`; falls back to Arma's native `viewDistance` if that variable is not set
- **Without ACE3** — reads Arma's native `viewDistance` directly

---

## Scripting API

Four functions are available for mission makers and mod authors. All are registered under the `AIC` tag and can be called from any machine.

| Function | Description |
|---|---|
| `[unit] call AIC_fnc_protect` | Permanently exclude a unit from culling. Auto-forwards to server from clients. |
| `[unit] call AIC_fnc_unprotect` | Return a protected unit to the normal culling pool. Auto-forwards to server from clients. |
| `[unit] call AIC_fnc_isCulled` | Returns `true` if the unit is currently culled (simulation disabled). |
| `[] call AIC_fnc_getStats` | Returns the last tick's statistics as a HashMap (keys: `active`, `los`, `noLos`, `culled`, `protected`, `override`, `total`, `serverFps`). |

See [docs/API.md](docs/API.md) for full parameter documentation and examples.

---

## Compatibility

- ✅ CBA_A3 (required by `aic_client`; optional for `aic_main` — enables Addon Options integration)
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
    │       ├── fn_preInit.sqf             # Settings — applies CBA values or hard-coded defaults
    │       ├── fn_registerSettings.sqf    # CBA Addon Options registration (no-op without CBA_A3)
    │       ├── fn_postInit.sqf            # Server loop + Zeus hook branching
    │       ├── fn_mainLoop.sqf            # Main culler loop (runs on server each tick)
    │       ├── fn_getCullDist.sqf         # Returns per-faction cull distance
    │       ├── fn_enableUnit.sqf          # Re-enables simulation on a unit
    │       ├── fn_disableUnit.sqf         # Disables simulation on a unit
    │       ├── fn_broadcastStats.sqf      # Sends stats to Zeus clients each tick
    │       ├── fn_updateStatusWindow.sqf  # Updates stat rows in the Zeus UI
    │       ├── fn_updateUnitLabel.sqf     # Updates the name prefix shown in Zeus
    │       ├── fn_toggleProtection.sqf    # Right-click toggle handler (Zeus context menu)
    │       ├── fn_protect.sqf             # API: protect a unit from culling
    │       ├── fn_unprotect.sqf           # API: return a unit to the culling pool
    │       ├── fn_isCulled.sqf            # API: returns true if unit is currently culled
    │       ├── fn_getStats.sqf            # API: returns last-tick stats HashMap
    │       ├── fn_waypointMonitor.sqf     # Detects Zeus/script-assigned waypoints
    │       ├── fn_setCullerEnabled.sqf    # Server-side culler on/off
    │       ├── fn_applySettings.sqf       # Server-side settings update (mid-op)
    │       ├── fn_initZeusHooks.sqf       # Status window lifecycle + 3D labels
    │       └── fn_createStatusWindow.sqf  # Builds the Zeus UI controls
    └── aic_client/                        # Client-side model renderer
        ├── config.cpp
        └── functions/
            ├── fn_clientPreInit.sqf       # Defaults + initialises renderer at mission start
            └── fn_clientLoop.sqf          # Per-tick LOS check and hideObject calls
```

---

## Changelog

### v3.8.0
- Switched surface intersection from `"FIRE"` LOD to `"VIEW"` LOD in both `aic_client` and `aic_main` — View Geometry is semantically correct for visual occlusion; Fire LOD is ballistic penetration geometry and produced incorrect results for many objects
- Fixed terrain-baked objects (trees, rocks) incorrectly occluding units — `lineIntersectsSurfaces` returns `objNull` for objects baked into the terrain; null refs are now treated as non-blocking, removing the need for `isKindOf "Tree"/"Bush"` guards
- Fixed remote-controlled units (Zeus RC) being hidden by `aic_client` — any unit currently being remote controlled by a player is always shown regardless of LOS result
- Fixed all units near a remote-controlling player being hidden — `aic_client` now detects when the local player is performing RC (`remoteControlled player` is non-null) and suspends occlusion entirely for that tick
- Fixed remote-controlled units being culled by `aic_main` — units with an active remote controller are excluded from the managed pool and their simulation is never disabled
- Fixed parachuting and free-falling units being culled by `aic_main` — units with a Z-velocity below -1 m/s are excluded from the managed pool, covering both units inside a parachute vehicle and the brief free-fall window between exiting an aircraft and parachute deployment
- Fixed backspace closing the Zeus UI when typing in configuration edit boxes — the Zeus display now intercepts the backspace key event and consumes it only when an edit field has keyboard focus, preventing the default Zeus close key binding from triggering mid-input
- Fixed backspace in any Zeus text box still toggling the Zeus HUD — the previous backspace consumer checked `ctrlType == 2` which misses Zeus's native text fields (wrapped in controls groups, type 15); updated to `!isNull (focusedCtrl _display)` so any focused control suppresses the toggle
- Fixed AIC status panel hide/show using invalid `displayAddEventHandler ["Hide"/"Show"]` event names — replaced with a 0.2s polling loop that watches `ctrlShown` on a native Zeus control (IDC < 9200) and syncs the AIC panel to match Zeus's actual HUD state
- Fixed "Generic error in expression" in `fn_mainLoop.sqf` LOS check — `exitWith { false }` inside `findIf` exits the entire `findIf` and returns a Boolean instead of an index, causing a type mismatch on `!= -1`; replaced with `if...then...else`
- Added terrain pre-check (`terrainIntersectASL`) to `aic_main`'s per-player LOS loop — cheap early-out consistent with `aic_client`'s two-tier approach; skips the expensive `lineIntersectsSurfaces` call when terrain already blocks the line
- Added color-coded Active count in the Zeus status window — green when below cap, yellow at exactly cap, orange up to 2× cap, flashing red above 2× cap
- Added **Protected from Culler** checkbox to Eden Editor unit attributes in the existing **Object: States** category — sets `AIC_zeusProtected` at mission start via the attribute expression, no scripting required
- Fixed conflict with the Hide Zeus module — `aic_client` was calling `hideObject false` on any visible unit, overriding `hideObjectGlobal` set by other modules and making the Zeus player visible to other players. The renderer now tracks which units it hid itself (`AIC_clientHid`) and only reveals those, leaving externally hidden units untouched
- Fixed enemy vehicle crews not triggering combat activation — `nearEntities [["CAManBase"], radius]` does not return units seated inside vehicles, so AI inside enemy vehicles were invisible to the combat detection pass. The check now also scans for nearby enemy vehicles via `nearEntities [["LandVehicle", "Air", "Ship"], radius]` and uses `effectiveCommander` to determine side and group
- Fixed AI units inside vehicles retaining their culled (simulation disabled) state — units excluded from the culling pool via `vehicle _x == _x` were never reaching the re-enable path, so any unit culled before boarding remained disabled indefinitely while seated. A dedicated pass now re-enables any culled unit whose `vehicle` is not itself on every tick
- Declared `cba_main` as a hard dependency in `aic_main` — it was already declared in `aic_client` but missing from `aic_main`, so the A3 launcher was not enforcing CBA was loaded for the server addon
- Fixed `aic_client` MP loop missing `vehicle _x == _x` guard — the SP loop correctly excluded AI seated in vehicles from the occlusion queue, but the MP loop was not applying the same filter, allowing vehicle crew to be hidden

### v3.7.0
- Rewrote `aic_client` loop with separate SP and MP paths — singleplayer uses the local AI pool; dedicated server MP filters to remote-only units. Listen server (host-client) is explicitly unsupported and documented
- Two-tier LOS: `terrainIntersectASL` runs first as a cheap early-out; `lineIntersectsSurfaces` (Fire Geometry LOD) is only run for units closer than `AIC_clientSurfaceRadius` that passed the terrain check, keeping the expensive raycast off the hot path for distant units
- Added `AIC_clientSurfaceRadius` (default 600m) — configurable via CBA Addon Options; beyond this distance only terrain LOS is used
- Surface intersection filter updated to exclude objects with `"net"`, `"bag"`, or `"bunker"` in their class name (case-insensitive) in addition to trees and bushes — camo nets and sandbag positions no longer incorrectly occlude units
- Switched surface intersection positions to `eyePos player` / `eyePos _unit` — accurate eye-level origin points rather than `getPosASL + [0,0,3]` approximation, fixing cases where the check was missing real obstructions or incorrectly blocking clear lines
- Ported ADS cone reveal system — units within ~30° of aim direction are force-revealed while holding precision aim or looking through an optic; `[ADS]` tag shown on debug HUD
- `AIC_clientSafeRadius` default raised from 75m to 150m
- Zeus camera bypass now uses `findDisplay 312` (curator display) — units in the sweep queue are unhidden as the sweep processes them while Zeus is open
- Changed `AIC_showNotifications` default to `false` — enable/disable popups are now opt-in
- Added `AIC_clientCorpseRadius` (default 300m) — dead AI beyond this distance are hidden without an LOS check, purely by distance. Set to 0 to always show corpses. Configurable per-client in Addon Options

### v3.6.0
- Added public scripting API: `AIC_fnc_protect`, `AIC_fnc_unprotect`, `AIC_fnc_isCulled`, `AIC_fnc_getStats` — mission makers and mod authors can now protect/unprotect units and query culler state without touching internal variables. Server-mutating calls auto-forward from client machines via `remoteExec`. See [docs/API.md](docs/API.md)
- Added `AIC_lastStats` HashMap — culler tick stats are stored after every pass and readable via `AIC_fnc_getStats` (keys: `active`, `los`, `noLos`, `culled`, `protected`, `override`, `total`, `serverFps`)
- Bidirectional combat detection: when unit A detects enemy unit B within `AIC_combatRadius`, both A's and B's groups are forced active in the same tick. Previously only A's side was kept live, leaving B's group potentially culled mid-engagement
- Added `behaviour _unit == "COMBAT"` check as a supplementary combat signal — units recently in contact stay active even if their enemy has briefly moved out of `AIC_combatRadius`
- Extracted waypoint monitor into `AIC_fnc_waypointMonitor` — the 65-line Zeus waypoint detection loop is now its own registered function rather than an inline spawn block in `fn_postInit.sqf`
- `allUnits` is now snapshotted once at the top of each culler tick and reused throughout — eliminates 3 redundant `allUnits` calls per tick
- Removed dead `AIC_fnc_registerSettings` call from `fn_preInit.sqf` (preInit runs before CBA's XEH phase, so the registration was immediately discarded by CBA)
- Added **Show Notifications** to CBA Addon Options (server-enforced) — when disabled, the in-game notification popup on culler enable/disable is suppressed

### v3.5.0
- Removed Zeus Client Renderer panel — all client renderer settings are now managed via CBA Addon Options
- Added **Enable Client Renderer** and **Safe Radius** to the **AI Culler - Client** addon options page (per-player)
- Added **Debug HUD** as a server-enforced setting under the **AI Culler** (Server) tab — enables the renderer overlay on all connected clients simultaneously when toggled by the server admin
- `AIC_clientRadius` now falls back to Arma's native `viewDistance` when ACE3 is not loaded (was hardcoded 2000m) and syncs every 30 seconds to track mid-mission changes — no ACE3 required for automatic radius tracking
- ACE3 branch: final fallback within the ACE path also uses `viewDistance` instead of 2000m, covering the edge case where ACE3 is loaded but its view distance variable is not yet set
- Fixed: CBA saved settings were being overwritten on load — `fn_clientPreInit.sqf` now uses `isNil` guards so hard-coded defaults only apply when CBA has not already populated the variable from the saved profile
- Fixed: `_hasAce` variable was not accessible inside the view distance poll thread — passed as a spawn parameter to keep scope clean

### v3.4.0
- Added CBA Addon Options integration — server settings (max AI, cull distances, interval, combat radius, debug) now appear under **Configure → Addon Options → AI Culler** and are applied automatically at mission start without editing any files. Server values are broadcast to all clients via CBA's `isGlobal` mechanism
- Added client renderer Addon Options page (**AI Culler - Client**) — each player can independently toggle unit name labels, 3D floating labels, and set their own 3D label draw distance
- The mod remains fully standalone-compatible: if CBA_A3 is not loaded, `fn_registerSettings` exits silently and `fn_preInit` falls back to hard-coded defaults as before
- Added Zeus FPS Graph panel — click **FPS Graph** in the status window to open a floating bar chart showing server FPS over the last 90 seconds. Y-axis auto-scales to the observed range and stabilizes when the sliding window is full. Title bar shows live average, min, and max

### v3.3.2
- Fixed: AI crew seated inside vehicles were incorrectly included in the culling pool — disabling simulation on a crew member can break the vehicle entirely. A `vehicle _x == _x` guard now excludes any unit that is mounted inside a vehicle from both the server culler and the client renderer
- Fixed: client renderer used `isKindOf "Man"` instead of `CAManBase` for its candidate filter (missed in v3.3.0) — same vehicle crew guard applied at the same time

### v3.3.1
- Fixed: `publicVariableClient` was passing the variable's value (a Number) instead of its name as a String — server FPS was never reaching Zeus clients
- Fixed: proximity priority for no-LOS AI under the active cap restored — v3.3.0 removed the ascending-distance sort on the no-LOS pool, causing distant units to claim cap slots ahead of closer ones
- Client renderer defaults tuned for 100–200 AI in radius: `AIC_clientSweepTicks` 4→3, `AIC_clientBudgetMax` 40→60 — sweeps 200 AI in ~0.8s and 100 AI in ~0.6s at the default 0.2s cadence

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
