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

Edit `@ai_culler/addons/aic_main/functions/fnc_preInit.sqf` and rebuild the PBO to adjust settings:

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

**At placement:** A "Protect from culler" checkbox appears in the Zeus placement panel for infantry. Tick it before confirming placement — that unit will never be culled.

> ⚠️ Requires Config Viewer verification before use — see `config.cpp` comments for details.

**On existing units:** Right-click any living AI infantry unit in Zeus → **"Toggle Culler Protection"**. Confirmation appears in system chat.

**Status window:** Opens automatically when Zeus is active. Displays live stats — Active, LOS, No-LOS, Culled, Protected. Click ▲/▼ to collapse or expand. The **"Disable Culler / Enable Culler"** button pauses and resumes culling entirely — all previously culled AI are re-enabled when disabled.

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
            ├── fnc_preInit.sqf           # Settings — edit to tune
            ├── fnc_postInit.sqf          # Entry point (server + curator branching)
            ├── fnc_mainLoop.sqf          # Main culler loop
            ├── fnc_enableUnit.sqf
            ├── fnc_disableUnit.sqf
            ├── fnc_getCullDist.sqf
            ├── fnc_broadcastStats.sqf    # Sends stats to Zeus clients each tick
            ├── fnc_toggleProtection.sqf  # Right-click toggle handler
            ├── fnc_setCullerEnabled.sqf  # Server-side culler on/off
            ├── fnc_initZeusHooks.sqf     # Context action + status window lifecycle
            ├── fnc_createStatusWindow.sqf
            └── fnc_updateStatusWindow.sqf
```

---

## Changelog

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
