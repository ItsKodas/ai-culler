# AI Culler — Mod Conversion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert the AI Culler SQF script into a standalone Arma 3 addon mod (`@ai_culler`) with vehicle exclusion, opt-in Zeus protection, a placement-time checkbox, a right-click toggle, and a collapsible in-Zeus status window.

**Architecture:** Single PBO addon (`aic_main`, prefix `aic`). Functions auto-loaded via `CfgFunctions` with `preInit`/`postInit` flags — no CBA required. Server-side culler loop starts at postInit; Zeus UI hooks activate only on curator machines detected via a `waitUntil` spawn. Stats broadcast from server to Zeus operators via `remoteExec` each tick. Status window controls injected directly into Zeus display 312 — no separate display creation.

**Tech Stack:** SQF (Arma 3 scripting language), Arma 3 CfgFunctions auto-loading, Arma 3 Config (config.cpp), no external dependencies.

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `@ai_culler/addons/aic_main/$PBOPREFIX$` | Create | PBO prefix declaration |
| `@ai_culler/addons/aic_main/config.cpp` | Create | CfgPatches, CfgFunctions, CfgVehicles (curatorInfoType) |
| `@ai_culler/addons/aic_main/functions/fnc_preInit.sqf` | Create | Settings globals (runs at preInit on all machines) |
| `@ai_culler/addons/aic_main/functions/fnc_postInit.sqf` | Create | Entry point — branches to culler loop (server) and Zeus hooks (curator) |
| `@ai_culler/addons/aic_main/functions/fnc_mainLoop.sqf` | Create | Main culler while-loop with vehicle exclusion and stat collection |
| `@ai_culler/addons/aic_main/functions/fnc_enableUnit.sqf` | Create | Re-enable a culled unit (guards with `AIC_disabled` flag) |
| `@ai_culler/addons/aic_main/functions/fnc_disableUnit.sqf` | Create | Disable a unit (guards with `AIC_disabled` flag) |
| `@ai_culler/addons/aic_main/functions/fnc_getCullDist.sqf` | Create | Return cull distance per faction |
| `@ai_culler/addons/aic_main/functions/fnc_broadcastStats.sqf` | Create | remoteExec stats to connected Zeus operators |
| `@ai_culler/addons/aic_main/functions/fnc_toggleProtection.sqf` | Create | Flip zeusProtected on a unit, notify Zeus via systemChat |
| `@ai_culler/addons/aic_main/functions/fnc_initZeusHooks.sqf` | Create | addCuratorContextAction + Zeus display lifecycle watcher |
| `@ai_culler/addons/aic_main/functions/fnc_createStatusWindow.sqf` | Create | Inject controls into Zeus display 312 |
| `@ai_culler/addons/aic_main/functions/fnc_updateStatusWindow.sqf` | Create | Update control text when new stats arrive |
| `init.sqf` | Delete | Replaced by CfgFunctions auto-loading |
| `src/AI_Culler.sqf` | Delete | Replaced by fnc_mainLoop.sqf |
| `src/fnc_enableUnit.sqf` | Delete | Replaced by mod version |
| `src/fnc_disableUnit.sqf` | Delete | Replaced by mod version |
| `src/fnc_getCullDist.sqf` | Delete | Replaced by mod version |
| `src/fnc_zeusProtect.sqf` | Delete | Removed — auto-protection logic eliminated |
| `config/settings.sqf` | Delete | Replaced by fnc_preInit.sqf |
| `README.md` | Modify | Update installation and usage docs |

**Status window control IDCs** (range chosen to minimise conflict risk):

| Control | IDC |
|---|---|
| Background | 9200 |
| Title text | 9201 |
| Collapse button | 9202 |
| Active label | 9203 |
| LOS label | 9204 |
| No-LOS label | 9205 |
| Culled label | 9206 |
| Protected label | 9207 |

---

### Task 1: Git init + mod scaffold

**Files:**
- Create: `.gitignore`
- Create: `@ai_culler/addons/aic_main/$PBOPREFIX$`
- Create: `@ai_culler/addons/aic_main/config.cpp`
- Create: `@ai_culler/addons/aic_main/functions/fnc_preInit.sqf` (stub)
- Create: `@ai_culler/addons/aic_main/functions/fnc_postInit.sqf` (stub)
- Create: `@ai_culler/addons/aic_main/functions/fnc_mainLoop.sqf` (stub)
- Create: `@ai_culler/addons/aic_main/functions/fnc_enableUnit.sqf` (stub)
- Create: `@ai_culler/addons/aic_main/functions/fnc_disableUnit.sqf` (stub)
- Create: `@ai_culler/addons/aic_main/functions/fnc_getCullDist.sqf` (stub)
- Create: `@ai_culler/addons/aic_main/functions/fnc_broadcastStats.sqf` (stub)
- Create: `@ai_culler/addons/aic_main/functions/fnc_toggleProtection.sqf` (stub)
- Create: `@ai_culler/addons/aic_main/functions/fnc_initZeusHooks.sqf` (stub)
- Create: `@ai_culler/addons/aic_main/functions/fnc_createStatusWindow.sqf` (stub)
- Create: `@ai_culler/addons/aic_main/functions/fnc_updateStatusWindow.sqf` (stub)

- [ ] **Step 1: Initialise git**

```bash
cd "f:/Projects/ai-culler"
git init
```

- [ ] **Step 2: Create .gitignore**

Create `f:/Projects/ai-culler/.gitignore`:
```
*.pbo
*.pbo.*.bisign
*.bikey
.hemtt/
```

- [ ] **Step 3: Create mod directory structure**

```bash
mkdir -p "f:/Projects/ai-culler/@ai_culler/addons/aic_main/functions"
```

- [ ] **Step 4: Create $PBOPREFIX$**

Create `f:/Projects/ai-culler/@ai_culler/addons/aic_main/$PBOPREFIX$` with this exact content (no trailing newline):
```
aic\aic_main
```

- [ ] **Step 5: Create config.cpp**

Create `f:/Projects/ai-culler/@ai_culler/addons/aic_main/config.cpp`:
```cpp
class CfgPatches {
    class aic_main {
        name = "AI Culler";
        author = "koda";
        url = "";
        requiredVersion = 1.98;
        requiredAddons[] = {};
        version = "1.0.0";
        versionStr = "1.0.0";
        versionAr[] = {1, 0, 0};
    };
};

class CfgFunctions {
    class AIC {
        tag = "AIC";
        class Main {
            file = "aic\aic_main\functions";
            class preInit      { preInit  = 1; };
            class postInit     { postInit = 1; };
            class mainLoop         {};
            class enableUnit       {};
            class disableUnit      {};
            class getCullDist      {};
            class broadcastStats   {};
            class toggleProtection {};
            class initZeusHooks    {};
            class createStatusWindow {};
            class updateStatusWindow {};
        };
    };
};
```

- [ ] **Step 6: Create stub function files**

Create each file below with the single-line comment shown. These prevent Arma from erroring on load before the functions are implemented.

`f:/Projects/ai-culler/@ai_culler/addons/aic_main/functions/fnc_preInit.sqf`:
```sqf
// AIC_fnc_preInit — stub
```

`f:/Projects/ai-culler/@ai_culler/addons/aic_main/functions/fnc_postInit.sqf`:
```sqf
// AIC_fnc_postInit — stub
```

`f:/Projects/ai-culler/@ai_culler/addons/aic_main/functions/fnc_mainLoop.sqf`:
```sqf
// AIC_fnc_mainLoop — stub
```

`f:/Projects/ai-culler/@ai_culler/addons/aic_main/functions/fnc_enableUnit.sqf`:
```sqf
// AIC_fnc_enableUnit — stub
```

`f:/Projects/ai-culler/@ai_culler/addons/aic_main/functions/fnc_disableUnit.sqf`:
```sqf
// AIC_fnc_disableUnit — stub
```

`f:/Projects/ai-culler/@ai_culler/addons/aic_main/functions/fnc_getCullDist.sqf`:
```sqf
// AIC_fnc_getCullDist — stub
```

`f:/Projects/ai-culler/@ai_culler/addons/aic_main/functions/fnc_broadcastStats.sqf`:
```sqf
// AIC_fnc_broadcastStats — stub
```

`f:/Projects/ai-culler/@ai_culler/addons/aic_main/functions/fnc_toggleProtection.sqf`:
```sqf
// AIC_fnc_toggleProtection — stub
```

`f:/Projects/ai-culler/@ai_culler/addons/aic_main/functions/fnc_initZeusHooks.sqf`:
```sqf
// AIC_fnc_initZeusHooks — stub
```

`f:/Projects/ai-culler/@ai_culler/addons/aic_main/functions/fnc_createStatusWindow.sqf`:
```sqf
// AIC_fnc_createStatusWindow — stub
```

`f:/Projects/ai-culler/@ai_culler/addons/aic_main/functions/fnc_updateStatusWindow.sqf`:
```sqf
// AIC_fnc_updateStatusWindow — stub
```

- [ ] **Step 7: Verify mod loads cleanly**

Build `aic_main.pbo` from `@ai_culler/addons/aic_main/` using Arma 3 Tools (PBO Manager or HEMTT). Load Arma with `-mod=@ai_culler`. Check the RPT log — there must be zero errors mentioning `aic_main` or `AIC`. A clean load with no config errors is success.

- [ ] **Step 8: Commit**

```bash
git add .
git commit -m "feat: scaffold @ai_culler mod with stub functions"
```

---

### Task 2: Settings globals — fnc_preInit.sqf

**Files:**
- Write: `@ai_culler/addons/aic_main/functions/fnc_preInit.sqf`

- [ ] **Step 1: Define expected RPT output**

When this task is complete, loading Arma with `-mod=@ai_culler` must produce this line in the RPT:
```
[AIC] Settings initialised
```

- [ ] **Step 2: Write fnc_preInit.sqf**

Replace the stub at `f:/Projects/ai-culler/@ai_culler/addons/aic_main/functions/fnc_preInit.sqf`:
```sqf
AIC_maxActiveAI     = 80;
AIC_distOpfor       = 1000;
AIC_distIndependent = 800;
AIC_distCivilian    = 400;
AIC_checkInterval   = 5;
AIC_debug           = true;

if (AIC_debug) then {
    diag_log "[AIC] Settings initialised";
};
```

- [ ] **Step 3: Rebuild PBO and verify in RPT**

Rebuild `aic_main.pbo`, load Arma. Confirm RPT contains:
```
[AIC] Settings initialised
```

- [ ] **Step 4: Commit**

```bash
git add "@ai_culler/addons/aic_main/functions/fnc_preInit.sqf"
git commit -m "feat: settings globals via preInit"
```

---

### Task 3: Init entry point — fnc_postInit.sqf

**Files:**
- Write: `@ai_culler/addons/aic_main/functions/fnc_postInit.sqf`

- [ ] **Step 1: Define expected RPT output**

On a hosted/dedicated server session the RPT must contain:
```
[AIC] Server — starting culler loop
```
On a client that is Zeus the RPT must contain:
```
[AIC] Curator machine — init Zeus hooks
```

- [ ] **Step 2: Write fnc_postInit.sqf**

Replace the stub at `f:/Projects/ai-culler/@ai_culler/addons/aic_main/functions/fnc_postInit.sqf`:
```sqf
if (isServer) then {
    if (AIC_debug) then { diag_log "[AIC] Server — starting culler loop"; };
    [] spawn AIC_fnc_mainLoop;
};

if (hasInterface) then {
    [] spawn {
        waitUntil { !isNull player };
        waitUntil { player == player };

        if (!isNull (getAssignedCuratorLogic player)) then {
            if (AIC_debug) then { diag_log "[AIC] Curator machine — init Zeus hooks"; };
            [] call AIC_fnc_initZeusHooks;
        };

        player addEventHandler ["CuratorAssigned", {
            if (AIC_debug) then { diag_log "[AIC] Curator assigned mid-mission — init Zeus hooks"; };
            [] call AIC_fnc_initZeusHooks;
        }];
    };
};
```

- [ ] **Step 3: Rebuild PBO and verify in RPT**

Host a mission with `@ai_culler` loaded. RPT must show `[AIC] Server — starting culler loop`. Open Zeus in that mission — RPT must show `[AIC] Curator machine — init Zeus hooks`. (The culler loop and Zeus hooks are stubs, so no further output yet.)

- [ ] **Step 4: Commit**

```bash
git add "@ai_culler/addons/aic_main/functions/fnc_postInit.sqf"
git commit -m "feat: postInit entry point with server and curator branching"
```

---

### Task 4: Core culler utility functions

**Files:**
- Write: `@ai_culler/addons/aic_main/functions/fnc_getCullDist.sqf`
- Write: `@ai_culler/addons/aic_main/functions/fnc_enableUnit.sqf`
- Write: `@ai_culler/addons/aic_main/functions/fnc_disableUnit.sqf`

These are ports of the original scripts. Variable renamed from `culler_disabled` to `AIC_disabled` for namespace consistency. Settings variables renamed from `AI_Culler_*` to `AIC_*`.

- [ ] **Step 1: Write fnc_getCullDist.sqf**

Replace stub at `f:/Projects/ai-culler/@ai_culler/addons/aic_main/functions/fnc_getCullDist.sqf`:
```sqf
params ["_unit"];

switch (side _unit) do {
    case east:       { AIC_distOpfor };
    case resistance: { AIC_distIndependent };
    case civilian:   { AIC_distCivilian };
    default:         { AIC_distOpfor };
};
```

- [ ] **Step 2: Write fnc_enableUnit.sqf**

Replace stub at `f:/Projects/ai-culler/@ai_culler/addons/aic_main/functions/fnc_enableUnit.sqf`:
```sqf
params ["_unit"];

if (_unit getVariable ["AIC_disabled", false]) then {
    _unit enableAI "ALL";
    _unit setVariable ["AIC_disabled", false];

    if (AIC_debug) then {
        diag_log format ["[AIC] Enabled: %1", _unit];
    };
};
```

- [ ] **Step 3: Write fnc_disableUnit.sqf**

Replace stub at `f:/Projects/ai-culler/@ai_culler/addons/aic_main/functions/fnc_disableUnit.sqf`:
```sqf
params ["_unit"];

if !(_unit getVariable ["AIC_disabled", false]) then {
    _unit disableAI "ALL";
    _unit setVariable ["AIC_disabled", true];

    if (AIC_debug) then {
        diag_log format ["[AIC] Disabled: %1", _unit];
    };
};
```

- [ ] **Step 4: Commit**

```bash
git add "@ai_culler/addons/aic_main/functions/fnc_getCullDist.sqf" "@ai_culler/addons/aic_main/functions/fnc_enableUnit.sqf" "@ai_culler/addons/aic_main/functions/fnc_disableUnit.sqf"
git commit -m "feat: port getCullDist, enableUnit, disableUnit to mod"
```

---

### Task 5: Main culler loop + stat broadcasting

**Files:**
- Write: `@ai_culler/addons/aic_main/functions/fnc_broadcastStats.sqf`
- Write: `@ai_culler/addons/aic_main/functions/fnc_mainLoop.sqf`

Stats are broadcast as 6 values: `[activeCount, losCount, noLosCount, outOfRangeCount, protectedCount, culledCount]`. The culled count is computed server-side (`count _allAI - _activeCount`) to keep client logic simple.

- [ ] **Step 1: Define expected RPT output**

After this task, hosting a mission with east/resistance/civilian infantry and loading `@ai_culler` must produce this in the RPT within 5 seconds:
```
[AIC] Starting culler loop
[AIC] Active: X / 80 | LOS: X | No-LOS: X | Out of range: X | Protected: 0 | Culled: X
```

- [ ] **Step 2: Write fnc_broadcastStats.sqf**

Replace stub at `f:/Projects/ai-culler/@ai_culler/addons/aic_main/functions/fnc_broadcastStats.sqf`:
```sqf
params ["_activeCount", "_losCount", "_noLosCount", "_outOfRangeCount", "_protectedCount", "_culledCount"];

{
    if (hasInterface _x && {!isNull (getAssignedCuratorLogic _x)}) then {
        [_activeCount, _losCount, _noLosCount, _outOfRangeCount, _protectedCount, _culledCount]
            remoteExecCall ["AIC_fnc_updateStatusWindow", _x];
    };
} forEach allPlayers;
```

- [ ] **Step 3: Write fnc_mainLoop.sqf**

Replace stub at `f:/Projects/ai-culler/@ai_culler/addons/aic_main/functions/fnc_mainLoop.sqf`:
```sqf
if !(isServer) exitWith {};

diag_log "[AIC] Starting culler loop";

while {true} do {
    private _players = allPlayers select { isPlayer _x };

    // Count protected infantry before the main filter excludes them
    private _protectedCount = {
        alive _x &&
        _x isKindOf "Man" &&
        !isPlayer _x &&
        (_x getVariable ["zeusProtected", false]) &&
        (side _x in [east, resistance, civilian])
    } count allUnits;

    // Managed pool: living AI infantry, unprotected, correct factions
    private _allAI = allUnits select {
        alive _x &&
        _x isKindOf "Man" &&
        !isPlayer _x &&
        !(_x getVariable ["zeusProtected", false]) &&
        (side _x in [east, resistance, civilian])
    };

    private _outOfRange   = [];
    private _inRangeNoLOS = [];
    private _inRangeLOS   = [];

    {
        private _unit     = _x;
        private _cullDist = [_unit] call AIC_fnc_getCullDist;
        private _nearestDist = 99999;
        private _hasLOS      = false;

        {
            private _dist = _x distance _unit;
            if (_dist < _nearestDist) then { _nearestDist = _dist; };
            if (_dist < _cullDist && !_hasLOS) then {
                if ([_x, _unit, 0] call BIS_fnc_checkVisibility > 0.5) then {
                    _hasLOS = true;
                };
            };
        } forEach _players;

        if (_nearestDist > _cullDist) then {
            _outOfRange pushBack [_unit, _nearestDist];
        } else {
            if (_hasLOS) then {
                _inRangeLOS pushBack [_unit, _nearestDist];
            } else {
                _inRangeNoLOS pushBack [_unit, _nearestDist];
            };
        };
    } forEach _allAI;

    _outOfRange   = [_outOfRange,   [], { _x select 1 }, "DESCEND"] call BIS_fnc_sortBy;
    _inRangeNoLOS = [_inRangeNoLOS, [], { _x select 1 }, "DESCEND"] call BIS_fnc_sortBy;

    { [_x select 0] call AIC_fnc_disableUnit; } forEach _outOfRange;

    private _activeCount = 0;
    {
        [_x select 0] call AIC_fnc_enableUnit;
        _activeCount = _activeCount + 1;
    } forEach _inRangeLOS;

    {
        private _unit = _x select 0;
        if (_activeCount < AIC_maxActiveAI) then {
            [_unit] call AIC_fnc_enableUnit;
            _activeCount = _activeCount + 1;
        } else {
            [_unit] call AIC_fnc_disableUnit;
        };
    } forEach _inRangeNoLOS;

    private _culledCount = (count _allAI) - _activeCount;

    if (AIC_debug) then {
        diag_log format [
            "[AIC] Active: %1 / %2 | LOS: %3 | No-LOS: %4 | Out of range: %5 | Protected: %6 | Culled: %7",
            _activeCount, AIC_maxActiveAI,
            count _inRangeLOS, count _inRangeNoLOS,
            count _outOfRange, _protectedCount, _culledCount
        ];
    };

    [_activeCount, count _inRangeLOS, count _inRangeNoLOS, count _outOfRange, _protectedCount, _culledCount]
        call AIC_fnc_broadcastStats;

    sleep AIC_checkInterval;
};
```

- [ ] **Step 4: Rebuild PBO and verify**

Host a mission with a mix of east infantry, a vehicle, and a civilian. Load `@ai_culler`. After 5 seconds the RPT must show the stat line. Confirm:
- The vehicle does NOT affect the counts (it is excluded by `isKindOf "Man"`)
- Placing a second Zeus-placed unit (all are Zeus-placed in your ops) — they all appear in Active/culled counts since `zeusProtected` is no longer auto-set

- [ ] **Step 5: Commit**

```bash
git add "@ai_culler/addons/aic_main/functions/fnc_mainLoop.sqf" "@ai_culler/addons/aic_main/functions/fnc_broadcastStats.sqf"
git commit -m "feat: main culler loop with vehicle exclusion and stat broadcasting"
```

---

### Task 6: Zeus placement checkbox — curatorInfoType

**Files:**
- Modify: `@ai_culler/addons/aic_main/config.cpp`

**This task requires a one-time research step using Arma 3 Tools.** The `curatorInfoType` class structure must be verified against BI's configs before implementing.

- [ ] **Step 1: Research curatorInfoType via Arma 3 Config Viewer**

Open **Arma 3 Tools → Config Viewer**. In the class tree, navigate to `CfgVehicles`. Find a crewed vehicle that shows the Crew checkbox in Zeus placement — e.g. `B_MRAP_01_F`. Look at its `curatorInfoType` property and note the class name it points to.

Then search for that class name in Config Viewer. Record:
1. The exact class hierarchy (what it inherits from)
2. The IDC of the checkbox control (e.g. `100`)
3. How the `statement` reads the checkbox value — specifically which `findDisplay` IDC it uses and what parameters `_this` contains
4. The `x`, `y`, `w`, `h` positioning values so our checkbox can be placed consistently

- [ ] **Step 2: Add curatorInfoType block to config.cpp**

Add the following block to `f:/Projects/ai-culler/@ai_culler/addons/aic_main/config.cpp` after the `CfgFunctions` block. Replace `<INHERIT_CLASS>`, `<CHECKBOX_IDC>`, `<DIALOG_IDD>`, and the positioning values with what you found in Step 1:

```cpp
// Forward declarations
class <INHERIT_CLASS>;
class Man;

class AIC_CuratorInfo_Man: <INHERIT_CLASS> {
    statement = "
        params ['_objects', '_curator'];
        private _protect = ctrlChecked ((findDisplay <DIALOG_IDD>) displayCtrl <CHECKBOX_IDC>);
        if (_protect) then {
            {_x setVariable ['zeusProtected', true, true]} forEach _objects;
            if (AIC_debug) then {
                diag_log format ['[AIC] Zeus protected at placement: %1 unit(s)', count _objects];
            };
        };
    ";
    class controls {
        // Copy the base control class name from Step 1 (e.g. RscCheckBox or the BI-specific variant)
        class AIC_ProtectCheckbox: <BASE_CHECKBOX_CLASS> {
            idc  = <CHECKBOX_IDC>;
            text = "Protect from culler";
            // Use positioning values from Step 1; adjust y offset if stacking below existing controls
            x = 0.05;
            y = 0.02;
            w = 0.4;
            h = 0.04;
        };
    };
};

class CfgVehicles {
    class Man {
        curatorInfoType = "AIC_CuratorInfo_Man";
    };
};
```

- [ ] **Step 3: Rebuild PBO and verify**

Rebuild, load Arma, open Zeus. Attempt to place any infantry unit. The placement panel must show a **"Protect from culler"** checkbox, unchecked by default.

Place a unit with the box **unchecked** — open Zeus debug console and run:
```sqf
hint str (nearestObjects [getPos player, ["Man"], 50] select 0 getVariable ["zeusProtected", false]);
```
Must show `false`.

Place a unit with the box **checked** — run the same check. Must show `true`.

Check RPT for:
```
[AIC] Zeus protected at placement: 1 unit(s)
```

- [ ] **Step 4: Commit**

```bash
git add "@ai_culler/addons/aic_main/config.cpp"
git commit -m "feat: add Protect from culler checkbox to Zeus infantry placement panel"
```

---

### Task 7: Zeus right-click toggle

**Files:**
- Write: `@ai_culler/addons/aic_main/functions/fnc_toggleProtection.sqf`
- Write: `@ai_culler/addons/aic_main/functions/fnc_initZeusHooks.sqf` (partial — context action only)

- [ ] **Step 1: Define expected behaviour**

After this task, right-clicking an AI infantry unit in Zeus must show **"Toggle Culler Protection"** in the context menu. Selecting it must:
- Toggle `zeusProtected` on that unit globally
- Show a system chat message to the Zeus operator: `[AI Culler] <name> — culler protection: ON` or `OFF`

- [ ] **Step 2: Write fnc_toggleProtection.sqf**

Replace stub at `f:/Projects/ai-culler/@ai_culler/addons/aic_main/functions/fnc_toggleProtection.sqf`:
```sqf
params ["_unit"];

private _newState = !(_unit getVariable ["zeusProtected", false]);
_unit setVariable ["zeusProtected", _newState, true];

private _msg = format [
    "[AI Culler] %1 — culler protection: %2",
    name _unit,
    if (_newState) then {"ON"} else {"OFF"}
];

[_msg, true] remoteExecCall ["systemChat", remoteExecutedOwner];

if (AIC_debug) then {
    diag_log format ["[AIC] toggled zeusProtected on %1 -> %2", _unit, _newState];
};
```

- [ ] **Step 3: Write fnc_initZeusHooks.sqf (context action only for now)**

Replace stub at `f:/Projects/ai-culler/@ai_culler/addons/aic_main/functions/fnc_initZeusHooks.sqf`:
```sqf
// Context action: toggle culler protection on AI infantry
{
    _x addCuratorContextAction [
        "Toggle Culler Protection",
        { [(_this select 0)] call AIC_fnc_toggleProtection; },
        { (_this select 0) isKindOf "Man" && !isPlayer (_this select 0) && alive (_this select 0) }
    ];
} forEach allCurators;
```

- [ ] **Step 4: Rebuild PBO and verify**

Host a mission, open Zeus, place an infantry unit. Right-click it — **"Toggle Culler Protection"** must appear. Select it:
- System chat shows `[AI Culler] <name> — culler protection: ON`
- Select again: shows `OFF`
- Context action must NOT appear when right-clicking a vehicle, a player, or a dead unit

- [ ] **Step 5: Commit**

```bash
git add "@ai_culler/addons/aic_main/functions/fnc_toggleProtection.sqf" "@ai_culler/addons/aic_main/functions/fnc_initZeusHooks.sqf"
git commit -m "feat: Zeus right-click toggle for culler protection"
```

---

### Task 8: Status window

**Files:**
- Write: `@ai_culler/addons/aic_main/functions/fnc_createStatusWindow.sqf`
- Write: `@ai_culler/addons/aic_main/functions/fnc_updateStatusWindow.sqf`
- Modify: `@ai_culler/addons/aic_main/functions/fnc_initZeusHooks.sqf` (add display lifecycle)

Controls are injected directly into Zeus display 312 using `ctrlCreate`. They are destroyed automatically when display 312 closes. The lifecycle is managed by a `waitUntil` polling loop — no CBA required.

- [ ] **Step 1: Define expected behaviour**

After this task, opening Zeus must automatically show a window in the top-right corner displaying live culler stats. Clicking ▲ collapses it to the title bar. Clicking ▼ expands it. Closing and reopening Zeus resets to expanded.

- [ ] **Step 2: Write fnc_createStatusWindow.sqf**

Replace stub at `f:/Projects/ai-culler/@ai_culler/addons/aic_main/functions/fnc_createStatusWindow.sqf`:
```sqf
params ["_display"];

if (isNull _display) exitWith {};

// Remove any existing window controls (makes this call idempotent)
{ ctrlDelete (_display displayCtrl _x); } forEach [9200,9201,9202,9203,9204,9205,9206,9207];

private _wx = safeZoneX + safeZoneW - 0.265;  // renamed to _wx to avoid forEach _x conflict
private _y  = safeZoneY + 0.025;
private _w  = 0.255;
private _rH = 0.033;
private _tH = 0.036;

// Background panel
private _bg = _display ctrlCreate ["RscText", 9200];
_bg ctrlSetPosition [_wx, _y, _w, _tH + (_rH * 5) + 0.012];
_bg ctrlSetBackgroundColor [0, 0, 0, 0.78];
_bg ctrlCommit 0;

// Title
private _title = _display ctrlCreate ["RscText", 9201];
_title ctrlSetPosition [_wx + 0.005, _y + 0.003, _w - 0.045, _tH - 0.006];
_title ctrlSetText "AI Culler";
_title ctrlSetBackgroundColor [0.12, 0.12, 0.12, 1];
_title ctrlCommit 0;

// Collapse/expand button
private _btn = _display ctrlCreate ["RscButton", 9202];
_btn ctrlSetPosition [_wx + _w - 0.042, _y + 0.002, 0.037, _tH - 0.004];
_btn ctrlSetText "▲";
_btn ctrlCommit 0;
_btn setVariable ["AIC_collapsed", false];

_btn ctrlAddEventHandler ["ButtonClick", {
    params ["_btn"];
    private _disp     = ctrlParent _btn;
    private _collapse = !(_btn getVariable ["AIC_collapsed", false]);
    _btn setVariable ["AIC_collapsed", _collapse];
    _btn ctrlSetText if (_collapse) then {"▼"} else {"▲"};
    _btn ctrlCommit 0;

    // Show/hide stat rows — _x here is the IDC from the forEach, not a position
    { (_disp displayCtrl _x) ctrlShow !_collapse; (_disp displayCtrl _x) ctrlCommit 0; }
        forEach [9203,9204,9205,9206,9207];

    // Resize background
    private _bg  = _disp displayCtrl 9200;
    private _pos = ctrlPosition _bg;
    private _tH2 = 0.036;
    private _rH2 = 0.033;
    _bg ctrlSetPosition [
        _pos select 0, _pos select 1, _pos select 2,
        if (_collapse) then {_tH2 + 0.004} else {_tH2 + (_rH2 * 5) + 0.012}
    ];
    _bg ctrlCommit 0;
}];

// Stat row labels — _x inside forEach is the label string, _wx is the window X position
private _labels = ["Active: -- / --", "LOS: --", "No-LOS: --", "Culled: --", "Protected: --"];
private _idcs   = [9203, 9204, 9205, 9206, 9207];

{
    private _ctrl = _display ctrlCreate ["RscText", _idcs select _forEachIndex];
    _ctrl ctrlSetPosition [_wx + 0.007, _y + _tH + 0.006 + (_rH * _forEachIndex), _w - 0.014, _rH - 0.004];
    _ctrl ctrlSetText _x;
    _ctrl ctrlCommit 0;
} forEach _labels;
```

- [ ] **Step 3: Write fnc_updateStatusWindow.sqf**

Replace stub at `f:/Projects/ai-culler/@ai_culler/addons/aic_main/functions/fnc_updateStatusWindow.sqf`:
```sqf
params ["_activeCount", "_losCount", "_noLosCount", "_outOfRangeCount", "_protectedCount", "_culledCount"];

private _display = findDisplay 312;
if (isNull _display) exitWith {};

private _texts = [
    format ["Active: %1 / %2", _activeCount, AIC_maxActiveAI],
    format ["LOS: %1",         _losCount],
    format ["No-LOS: %1",      _noLosCount],
    format ["Culled: %1",      _culledCount],
    format ["Protected: %1",   _protectedCount]
];

{
    private _ctrl = _display displayCtrl ([9203,9204,9205,9206,9207] select _forEachIndex);
    if (!isNull _ctrl) then {
        _ctrl ctrlSetText _x;
        _ctrl ctrlCommit 0;
    };
} forEach _texts;
```

- [ ] **Step 4: Replace fnc_initZeusHooks.sqf with complete version**

Replace the full content of `f:/Projects/ai-culler/@ai_culler/addons/aic_main/functions/fnc_initZeusHooks.sqf`:
```sqf
// Context action: toggle culler protection on AI infantry
{
    _x addCuratorContextAction [
        "Toggle Culler Protection",
        { [(_this select 0)] call AIC_fnc_toggleProtection; },
        { (_this select 0) isKindOf "Man" && !isPlayer (_this select 0) && alive (_this select 0) }
    ];
} forEach allCurators;

// Status window lifecycle: poll for Zeus display opening and closing
[] spawn {
    while {true} do {
        // Wait for Zeus display to open
        waitUntil { !isNull (findDisplay 312) };
        [findDisplay 312] call AIC_fnc_createStatusWindow;

        // Wait for Zeus display to close
        waitUntil { isNull (findDisplay 312) };
    };
};
```

- [ ] **Step 5: Rebuild PBO and verify**

Host a mission and open Zeus. Verify:
- Status window appears in the top-right immediately on Zeus open
- Shows `Active: -- / --` placeholders initially, then live data within 5 seconds (one culler tick)
- ▲ button collapses to title bar only, ▼ expands back
- Closing Zeus and reopening restores the window in expanded state
- The culler context action still works (right-click an infantry unit)

- [ ] **Step 6: Commit**

```bash
git add "@ai_culler/addons/aic_main/functions/fnc_createStatusWindow.sqf" "@ai_culler/addons/aic_main/functions/fnc_updateStatusWindow.sqf" "@ai_culler/addons/aic_main/functions/fnc_initZeusHooks.sqf"
git commit -m "feat: collapsible Zeus status window with live culler stats"
```

---

### Task 9: Remove old script files + update README

**Files:**
- Delete: `init.sqf`
- Delete: `src/AI_Culler.sqf`
- Delete: `src/fnc_enableUnit.sqf`
- Delete: `src/fnc_disableUnit.sqf`
- Delete: `src/fnc_getCullDist.sqf`
- Delete: `src/fnc_zeusProtect.sqf`
- Delete: `config/settings.sqf`
- Modify: `README.md`

- [ ] **Step 1: Delete old files**

```bash
cd "f:/Projects/ai-culler"
rm init.sqf
rm src/AI_Culler.sqf src/fnc_enableUnit.sqf src/fnc_disableUnit.sqf src/fnc_getCullDist.sqf src/fnc_zeusProtect.sqf
rm config/settings.sqf
```

- [ ] **Step 2: Update README.md**

Replace the full content of `f:/Projects/ai-culler/README.md`:
```markdown
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
| `AIC_debug` | true | RPT logging on/off |

---

## Zeus Usage

**At placement:** A "Protect from culler" checkbox appears in the Zeus placement panel for infantry. Tick it before confirming placement — that unit will never be culled.

**On existing units:** Right-click any living AI infantry unit in Zeus → **"Toggle Culler Protection"**. Confirmation appears in system chat.

**Status window:** Opens automatically when Zeus is active. Displays live stats — Active, LOS, No-LOS, Culled, Protected. Click ▲/▼ to collapse or expand.

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
            ├── fnc_preInit.sqf          # Settings — edit to tune
            ├── fnc_postInit.sqf         # Entry point
            ├── fnc_mainLoop.sqf         # Culler loop
            ├── fnc_enableUnit.sqf
            ├── fnc_disableUnit.sqf
            ├── fnc_getCullDist.sqf
            ├── fnc_broadcastStats.sqf
            ├── fnc_toggleProtection.sqf
            ├── fnc_initZeusHooks.sqf
            ├── fnc_createStatusWindow.sqf
            └── fnc_updateStatusWindow.sqf
```

---

## Changelog

### v2.0.0
- Converted from mission script to standalone mod — no mission init.sqf required
- Vehicles permanently excluded from culling
- Zeus auto-protection removed — all units enter culler pool by default
- Added "Protect from culler" checkbox to Zeus infantry placement panel
- Added "Toggle Culler Protection" Zeus right-click context action
- Added collapsible in-Zeus status window with live stats
- Settings and function variables renamed to AIC_* prefix

### v1.0.0
- Initial release
```

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "chore: remove legacy script files, update README for v2.0.0"
```
