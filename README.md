# AI Culler — Arma 3 Server Performance Mod

A lightweight server-side mod that intelligently manages AI simulation across all factions based on player proximity, line of sight, and Zeus activity. Designed for large milsim ops with 60+ players and high AI counts.

---

## The Problem

Arma 3 simulates every AI unit simultaneously on a fixed cycle. Beyond ~150 units this causes periodic frame spikes as the server chokes on the processing load — even with LAMBS and Headless Clients.

## The Solution

AI Culler caps the number of actively simulating units and prioritises which ones matter most. Each unit is classified into one of five states every tick:

| State | Condition | Simulation |
|---|---|---|
| **Protected** | Marked via right-click or placement flag | Always active |
| **Override** | Zeus has assigned waypoints to the group | Always active |
| **Active (LOS)** | In range and player has line of sight | Always active |
| **Active (No-LOS)** | In range but no LOS | Active only if under cap |
| **Culled** | Beyond faction cull distance | Always disabled |

When a group is in **Override** or any unit in range is engaged in **AI vs AI combat**, simulation is forced on regardless of player proximity or the active unit cap.

Vehicles are never culled regardless of distance or LOS.

---

## Installation

1. Copy the `@ai_culler` folder into your Arma 3 directory
2. Add `-mod=@ai_culler` to your **server** and **Zeus client** launch parameters
3. No mission changes required — no `init.sqf` entry needed

---

## Configuration

### Mid-op (Zeus settings panel)

Open Zeus → click **"Settings"** in the AIC status window to adjust values live without restarting. Click **Apply** to push changes to the server immediately. Values sync to all connected clients via `publicVariable`.

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

### Pre-op (edit defaults)

To change the defaults that load at mission start, edit `@ai_culler/addons/aic_main/functions/fn_preInit.sqf` and rebuild the PBO:

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

## Zeus Usage

### Status window

Opens automatically when Zeus is active. Displays live stats across all managed AI. Click **▲/▼** to collapse or expand.

| Row | Description |
|---|---|
| Active | Currently simulating units / cap |
| LOS | Units active because a player has line of sight |
| No-LOS | Units active due to proximity but no LOS |
| Culled | Units with simulation disabled |
| Protected | Units excluded from culling entirely |
| Override | Units active because Zeus assigned their group a waypoint |

Press **Backspace** to hide or show the AIC panel without affecting Zeus's own HUD.

### Buttons

- **Disable Culler / Enable Culler** — pauses and resumes culling entirely. All previously culled AI are re-enabled when disabled.
- **Settings** — expands an inline panel to adjust all config values live. Click **Apply** to push changes to the server.

### Zeus waypoint Override

When Zeus assigns a move order to a group, AI Culler detects the new waypoint within one poll interval (default 5s) and activates the group regardless of how far they are from players. The Override label appears on each unit's 3D floating label and increments the Override counter in the status window.

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

If **ZEN Enhanced Zeus** is loaded, a **Toggle Culler Protection** option appears in the right-click context menu for any AI infantry. This is the fastest way to protect units mid-op without accessing the settings panel.

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
    └── aic_main/
        ├── config.cpp
        └── functions/
            ├── fn_preInit.sqf            # Settings — edit to tune defaults
            ├── fn_postInit.sqf           # Server loop + Zeus hook branching
            ├── fn_mainLoop.sqf           # Main culler loop (runs on server each tick)
            ├── fn_getCullDist.sqf        # Returns per-faction cull distance
            ├── fn_enableUnit.sqf         # Re-enables simulation on a unit
            ├── fn_disableUnit.sqf        # Disables simulation on a unit
            ├── fn_broadcastStats.sqf     # Sends stats to Zeus clients each tick
            ├── fn_updateStatusWindow.sqf # Updates stat rows in the Zeus UI
            ├── fn_updateUnitLabel.sqf    # Updates the name prefix shown in Zeus
            ├── fn_toggleProtection.sqf   # Right-click toggle handler
            ├── fn_setCullerEnabled.sqf   # Server-side culler on/off
            ├── fn_applySettings.sqf      # Server-side settings update (mid-op)
            ├── fn_initZeusHooks.sqf      # Status window lifecycle + 3D labels
            └── fn_createStatusWindow.sqf # Builds the Zeus UI controls
```

---

## Changelog

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
