# AI Culler — Arma 3 Server Performance Mod

A lightweight server-side mod that intelligently manages AI simulation across all factions based on player proximity and line of sight. Designed for large milsim ops with 60+ players and high AI counts.

---

## The Problem

Arma 3 simulates every AI unit simultaneously on a fixed cycle. Beyond ~150 units this causes periodic frame spikes as the server chokes on the processing load — even with LAMBS and Headless Clients.

## The Solution

AI Culler caps the number of actively simulating units and prioritises which ones matter most using a three-tier system:

| Priority | Condition | Action |
|---|---|---|
| 🔴 Always cull | Beyond faction cull distance | Always disabled |
| 🟡 Cap dependent | In range, no player LOS | Disabled only if over cap |
| 🟢 Never cull | In range, player has LOS | Always active |

Vehicles are never culled regardless of distance or LOS.

---

## Installation

1. Copy the `@ai_culler` folder into your Arma 3 directory
2. Add `-mod=@ai_culler` to your **server** and **Zeus client** launch parameters
3. No mission changes required — no `init.sqf` entry needed

---

## Configuration

### Mid-op (Zeus settings panel)

Open Zeus → click **"Settings"** in the status window to adjust values live without restarting:

| Field | Variable | Default |
|---|---|---|
| Max AI | `AIC_maxActiveAI` | 80 |
| Dist OPFOR | `AIC_distOpfor` | 1000m |
| Dist Indep | `AIC_distIndependent` | 800m |
| Dist Civ | `AIC_distCivilian` | 400m |
| Interval(s) | `AIC_checkInterval` | 5s |

Changes take effect on the next culler tick. Values sync to all connected Zeus clients via `publicVariable`.

### Pre-op (edit defaults)

To change the defaults that load at mission start, edit `@ai_culler/addons/aic_main/functions/fnc_preInit.sqf` and rebuild the PBO:

| Variable | Default | Description |
|---|---|---|
| `AIC_maxActiveAI` | 80 | Hard cap on simultaneously active AI |
| `AIC_distOpfor` | 1000m | Cull distance for Opfor (east) |
| `AIC_distIndependent` | 800m | Cull distance for Independent |
| `AIC_distCivilian` | 400m | Cull distance for Civilians |
| `AIC_checkInterval` | 5s | How often the culler runs |
| `AIC_debug` | true | RPT logging — set to `false` for live ops |

---

## Zeus Usage

**Status window:** Opens automatically when Zeus is active. Displays live stats — Active, LOS, No-LOS, Culled, Protected. Click ▲/▼ to collapse or expand.

- **Disable Culler / Enable Culler** — pauses and resumes culling entirely. All previously culled AI are re-enabled when disabled.
- **Settings** — expands an inline panel to adjust Max AI, cull distances, and check interval live. Click Apply to push changes to the server immediately.

---

## Compatibility

- ✅ LAMBS Danger
- ✅ Headless Clients
- ✅ Civilian Presence Module
- ✅ Zeus / Curator
- ✅ ACE3
- ⚠️ Vcom AI — not tested, may conflict

---

## Project Structure

```
@ai_culler/
└── addons/
    └── aic_main/
        ├── config.cpp
        └── functions/
            ├── fn_preInit.sqf           # Settings — edit to tune
            ├── fn_postInit.sqf          # Entry point (server + curator branching)
            ├── fn_mainLoop.sqf          # Main culler loop
            ├── fn_enableUnit.sqf
            ├── fn_disableUnit.sqf
            ├── fn_getCullDist.sqf
            ├── fn_broadcastStats.sqf    # Sends stats to Zeus clients each tick
            ├── fn_toggleProtection.sqf  # Right-click toggle handler
            ├── fn_setCullerEnabled.sqf  # Server-side culler on/off
            ├── fn_applySettings.sqf     # Server-side settings update (mid-op)
            ├── fn_initZeusHooks.sqf     # Context action + status window lifecycle
            ├── fn_createStatusWindow.sqf
            └── fn_updateStatusWindow.sqf
```

---

## Changelog

### v2.1.0
- Added inline Settings panel to Zeus status window — adjust Max AI, cull distances, and check interval mid-op without rebuilding the PBO
- Settings changes sync to all Zeus clients via `publicVariable`

### v2.0.0
- Converted from mission script to standalone mod — no mission `init.sqf` required
- Vehicles permanently excluded from culling
- Zeus auto-protection removed — all Zeus-placed units enter the culler pool by default
- Added "Protect from culler" checkbox to Zeus infantry placement panel (requires Config Viewer verification)
- Added "Toggle Culler Protection" Zeus right-click context action
- Added collapsible in-Zeus status window with live stats
- Added "Disable/Enable Culler" toggle button in the status window
- Settings and variables renamed to `AIC_*` prefix

### v1.0.0
- Initial release as mission script
