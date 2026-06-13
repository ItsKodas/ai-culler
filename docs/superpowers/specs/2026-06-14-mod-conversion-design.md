# AI Culler — Mod Conversion Design Spec
**Date:** 2026-06-14

## Overview

Convert AI Culler from a mission-embedded SQF script into a standalone Arma 3 addon mod (`@ai_culler`). Alongside the conversion, fix the Zeus protection logic to match how the ops actually run (all units placed by Zeus), add a placement-time protection checkbox, a right-click toggle for existing units, and a collapsible in-Zeus status window.

---

## 1. Mod Structure

Single addon PBO, prefix `aic`.

```
@ai_culler/
└── addons/
    └── aic_main/
        ├── $PBOPREFIX$              # aic\aic_main
        ├── config.cpp               # CfgPatches, CfgFunctions, CfgVehicles, RscDisplays
        ├── XEH_preInit.sqf          # Register settings globals
        ├── XEH_postInit.sqf         # Start culler (server) / init Zeus hooks (curator)
        └── functions/
            ├── fnc_mainLoop.sqf     # Main culler while-loop
            ├── fnc_enableUnit.sqf   # Re-enable a culled unit
            ├── fnc_disableUnit.sqf  # Disable a unit
            ├── fnc_getCullDist.sqf  # Per-faction cull distance
            └── fnc_toggleProtection.sqf  # Toggle zeusProtected on a unit
```

**No external dependencies.** No CBA, no ACE required. Compatible with both.

Users install `@ai_culler` in their mod list. Nothing goes in the mission folder — no `init.sqf` entry required.

---

## 2. Culler Logic Changes

### 2a. Vehicle exclusion
The `_allAI` filter in `fnc_mainLoop.sqf` gains one additional condition:

```sqf
isKindOf [_x, "Man"]
```

Vehicles (land, air, sea) are permanently excluded from culling — they always simulate regardless of distance or player proximity. No config toggle for this; it is unconditional.

### 2b. Zeus auto-protection removed
`fnc_zeusProtect.sqf` is deleted. The `addCuratorPlacedEventHandler` that previously flagged every Zeus-placed unit as `zeusProtected = true` is gone.

The `zeusProtected` variable remains as the protection mechanism — it is just no longer set automatically. All units start unprotected and enter the culler pool by default. Zeus opts specific units in via the placement checkbox or right-click toggle.

### 2c. Function loading
Functions are registered in `CfgFunctions` in `config.cpp` and auto-loaded by Arma's init system. The manual `compile preprocessFileLineNumbers` calls are dropped entirely. Settings globals are initialised in `XEH_preInit.sqf`.

### 2d. Settings (unchanged values, new location)
All existing config variables are preserved with the same defaults:

| Variable | Default |
|---|---|
| `AIC_maxActiveAI` | 80 |
| `AIC_distOpfor` | 1000 |
| `AIC_distIndependent` | 800 |
| `AIC_distCivilian` | 400 |
| `AIC_checkInterval` | 5 |
| `AIC_debug` | true |

Variables are renamed from `AI_Culler_*` to `AIC_*` to match the mod prefix convention.

---

## 3. Zeus Integration

### 3a. Placement checkbox
A `curatorInfoType` class is defined in `config.cpp` and applied to the `Man` base class in `CfgVehicles`. This adds a **"Protect from culler"** checkbox to the Zeus placement panel for all infantry.

- Checkbox is **unchecked by default** — unit enters the culler pool
- When Zeus confirms placement with the box ticked, the placed unit receives `setVariable ["zeusProtected", true, true]`
- Exact `curatorInfoType` class structure is confirmed during build by referencing BI's existing crew checkbox implementation (`CuratorInfo_Tank` / `CuratorInfo_Car`) as a template

Only applied to `Man`. Vehicles have no placement checkbox — they are excluded at the culler level, not the Zeus level.

### 3b. Right-click toggle
`addCuratorContextAction` is called in `XEH_postInit.sqf` on any machine that owns a curator object. This adds **"Toggle Culler Protection"** to the Zeus right-click context menu. The action condition restricts it to living AI infantry only: `_this isKindOf "Man" && !isPlayer _this && alive _this`. It does not appear on vehicles, players, or dead units.

Selecting it calls `fnc_toggleProtection`:
- Flips `zeusProtected` (`true` → `false` or `false` → `true`) with `setVariable [_, _, true]` to broadcast globally
- Sends a system chat message to the Zeus operator confirming the new state: `"[AI Culler] Unit protected: YES"` / `"[AI Culler] Unit protected: NO"`

---

## 4. Zeus Status Window

### 4a. Display definition
A non-blocking `RscDisplay` class defined in `config.cpp`. Renders as an overlay on top of the Zeus interface without blocking Zeus interaction.

**Position:** Fixed top-right corner, small footprint.

**Expanded state:**
```
┌─ AI Culler ──────────[▲]─┐
│  Active     74 / 80       │
│  LOS          12          │
│  No-LOS       62          │
│  Culled       45          │
│  Protected     8          │
└───────────────────────────┘
```

**Collapsed state:**
```
┌─ AI Culler ──────────[▼]─┐
```

The toggle button (▲/▼) collapses and expands the window in place. Collapse state is a local variable on the Zeus client — no server involvement. State persists for the duration of the Zeus session; resets to expanded next time Zeus opens.

### 4b. Lifecycle
A `displayAdded` event handler in `XEH_postInit.sqf` watches for display 312 (the Zeus interface) opening. When it appears, the status window is created. When display 312 closes, the status window is destroyed. At postInit, display 312 is also checked immediately (`findDisplay 312`) in case Zeus was already open before the mod initialised — if found, the window is created straight away without waiting for the EH.

### 4c. Data flow
At the end of each culler tick, the server collects the stats (`_activeCount`, `count _inRangeLOS`, `count _inRangeNoLOS`, `count _outOfRange`, protected unit count) and `remoteExec`s them to connected Zeus operators. The protected unit count is gathered separately, before the `_allAI` filter, by counting all living infantry with `getVariable ["zeusProtected", false]` set to `true` — since protected units are excluded from `_allAI` they would otherwise not be visible to the loop.

Target condition for remoteExec: `hasInterface && !isNull (getAssignedCuratorLogic player)`.

The status window updates its text controls when new data arrives. No polling, no per-frame update cost on the client.

---

## 5. Compatibility

- No mission `init.sqf` required
- LAMBS Danger — compatible (culler operates on simulation, not AI behaviour)
- Headless Clients — compatible (culler runs on server, HC owns groups normally)
- Civilian Presence Module — compatible (civilians included in culler pool)
- ACE3 — compatible
- Zeus / Curator — fully integrated (see section 3)
- Vcom AI — untested, may conflict

---

## 6. Out of Scope

- Blufor / independent player faction AI (only `east`, `resistance`, `civilian` managed)
- Per-unit cull distance overrides
- Mission-maker API for scripted protection
- Workshop publication / signing
