# v3.6.0 Optimization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Improve server performance, fix gameplay correctness gaps in combat detection, clean up dead code, and expose a public API so other mods and mission scripts can interact with AI Culler safely.

**Architecture:** Six independent improvements applied to `aic_main`. The main loop gains a single `allUnits` snapshot, a restructured combat block that handles bidirectional activation and behaviour-state detection, and a `AIC_lastStats` store for the new stats API. The waypoint monitor is extracted from `fn_postInit.sqf` into its own file. Four new public API functions are registered in `config.cpp` and documented in `docs/API.md`.

**Tech Stack:** SQF (Arma 3 scripting), CBA_A3, AddonBuilder.exe for PBO compilation.

> **SQF testing note:** There is no automated test runner. Verification steps use RPT log output and in-game observation. The build command is `.\build.ps1` from the repo root. RPT logs are at `%LOCALAPPDATA%\Arma 3\`.

---

## File Map

| Action | Path | What changes |
|---|---|---|
| Modify | `@ai_culler/addons/aic_main/functions/fn_mainLoop.sqf` | allUnits snapshot, combat restructure, AIC_lastStats store |
| Modify | `@ai_culler/addons/aic_main/functions/fn_preInit.sqf` | Remove dead registerSettings call |
| Modify | `@ai_culler/addons/aic_main/functions/fn_postInit.sqf` | Replace inline waypoint loop with spawn call |
| Create | `@ai_culler/addons/aic_main/functions/fn_waypointMonitor.sqf` | Extracted waypoint detection loop |
| Create | `@ai_culler/addons/aic_main/functions/fn_protect.sqf` | Public API — protect a unit |
| Create | `@ai_culler/addons/aic_main/functions/fn_unprotect.sqf` | Public API — unprotect a unit |
| Create | `@ai_culler/addons/aic_main/functions/fn_isCulled.sqf` | Public API — query cull state |
| Create | `@ai_culler/addons/aic_main/functions/fn_getStats.sqf` | Public API — return last tick stats |
| Modify | `@ai_culler/addons/aic_main/config.cpp` | Register four new API functions and fn_waypointMonitor |
| Create | `docs/API.md` | Public API reference |
| Modify | `README.md` | Add API section |

---

## Task 1: Single `allUnits` snapshot in fn_mainLoop.sqf

**Files:**
- Modify: `@ai_culler/addons/aic_main/functions/fn_mainLoop.sqf`

Currently `allUnits` is called 4 separate times per tick — once in the disabled branch, once for protected count, once for the managed pool, and once for the override count. Each call allocates a fresh array. At 400+ units this is wasted work.

- [ ] **Step 1: Add the snapshot at the top of the loop body**

Open `fn_mainLoop.sqf`. After the opening `while {true} do {` on line 5, add one line:

```sqf
while {true} do {
    private _allUnitsRaw = allUnits;
```

- [ ] **Step 2: Replace all four `allUnits` references with `_allUnitsRaw`**

Apply these four replacements in order:

**Line ~8 (disabled branch):**
```sqf
// Before
private _toEnable = allUnits select { _x getVariable ["AIC_disabled", false] };

// After
private _toEnable = _allUnitsRaw select { _x getVariable ["AIC_disabled", false] };
```

**Line ~13 (disabled branch total count):**
```sqf
// Before
private _totalAI = { alive _x && _x isKindOf "CAManBase" && !isPlayer _x } count allUnits;

// After
private _totalAI = { alive _x && _x isKindOf "CAManBase" && !isPlayer _x } count _allUnitsRaw;
```

**Lines ~24-32 (protected count):**
```sqf
// Before
private _protectedCount = {
    alive _x &&
    _x isKindOf "CAManBase" &&
    vehicle _x == _x &&
    !isPlayer _x &&
    (_x getVariable ["AIC_zeusProtected", false]) &&
    (side _x in [west, east, resistance, civilian])
} count allUnits;

// After
private _protectedCount = {
    alive _x &&
    _x isKindOf "CAManBase" &&
    vehicle _x == _x &&
    !isPlayer _x &&
    (_x getVariable ["AIC_zeusProtected", false]) &&
    (side _x in [west, east, resistance, civilian])
} count _allUnitsRaw;
```

**Lines ~36-43 (managed pool):**
```sqf
// Before
private _allAI = allUnits select {

// After
private _allAI = _allUnitsRaw select {
```

- [ ] **Step 3: Verify the file has no remaining bare `allUnits` references in the loop body**

Search the file for `allUnits`. The only occurrence that should remain is the `_allUnitsRaw = allUnits` assignment you just added. If any others exist, replace them.

- [ ] **Step 4: Commit**

```bash
git add "@ai_culler/addons/aic_main/functions/fn_mainLoop.sqf"
git commit -m "perf: snapshot allUnits once per tick in mainLoop (was 4 separate calls)"
```

---

## Task 2: Remove dead preInit settings registration

**Files:**
- Modify: `@ai_culler/addons/aic_main/functions/fn_preInit.sqf`

`fn_preInit.sqf` calls `AIC_fnc_registerSettings` during the preInit phase. CBA resets its settings registry when its own XEH PreInit starts immediately after — wiping everything that was just registered. The real registration happens in `fn_postInit.sqf`. The preInit call does nothing except look like it does something.

- [ ] **Step 1: Remove the dead call and its comment**

Open `fn_preInit.sqf`. The current top of the file looks like:

```sqf
// Register CBA Addon Options settings first so variables have user-configured
// values before any other code runs. No-op if CBA_A3 is not loaded.
[] call AIC_fnc_registerSettings;

// Hard-coded defaults — only applied for variables still undefined after the
// CBA registration above (i.e. CBA is absent, or a variable was not registered).
```

Replace with:

```sqf
// Hard-coded defaults — applied when CBA_A3 is not loaded or a variable has
// not yet been populated by CBA (CBA registration happens in postInit).
```

- [ ] **Step 2: Commit**

```bash
git add "@ai_culler/addons/aic_main/functions/fn_preInit.sqf"
git commit -m "chore: remove dead CBA registration call from preInit (CBA wipes it immediately)"
```

---

## Task 3: Restructure combat detection — bidirectional activation + behaviour check

**Files:**
- Modify: `@ai_culler/addons/aic_main/functions/fn_mainLoop.sqf`

Two gaps in the current combat detection:

1. When unit A detects unit B as an enemy, only unit A is forced active. Unit B runs its own independent check and may get culled if no player is nearby — freezing one side of an engagement.
2. AI in `"COMBAT"` behaviour from a recent engagement (enemy has moved away) lose forced activation as soon as `nearEntities` finds nobody, even though they're still tactically hot.

The fix restructures the combat block to: run `nearEntities` once per unit, collect enemy groups into a shared `_forceActiveGroups` list, and supplement with a `behaviour` check. The `_forceActiveGroups` list is checked at the start of each unit's evaluation so enemy groups are activated even if no player is nearby.

- [ ] **Step 1: Add `_forceActiveGroups` declaration before the forEach loop**

Find the line that declares `_labelUpdates`:
```sqf
private _labelUpdates = [];
```

Add one line immediately after:
```sqf
private _labelUpdates = [];
private _forceActiveGroups = [];
```

- [ ] **Step 2: Replace the combat detection block inside the forEach**

Find the existing combat detection block (currently lines ~72-82):

```sqf
        private _inCombat = side _unit != civilian && {
            _unit nearEntities [["CAManBase"], AIC_combatRadius] findIf {
                alive _x && !isPlayer _x && side _x != civilian &&
                (side _x getFriend side _unit) < 0.6
            } != -1
        };

        if ((group _unit) getVariable ["AIC_zeusWaypoint", false] || _inCombat) then {
            // Zeus-assigned waypoint or AI vs AI combat — active regardless of player proximity
            _inRangeLOS pushBack _unit;
        } else {
```

Replace the entire block with:

```sqf
        // Combat detection: one nearEntities call, bidirectional group activation,
        // supplemented by behaviour state for units recently in contact.
        private _inCombat = false;
        if (side _unit != civilian) then {
            if (behaviour _unit == "COMBAT") then {
                _inCombat = true;
            } else {
                private _combatEnemies = _unit nearEntities [["CAManBase"], AIC_combatRadius] select {
                    alive _x && !isPlayer _x && side _x != civilian &&
                    (side _x getFriend side _unit) < 0.6
                };
                if (_combatEnemies isNotEqualTo []) then {
                    _inCombat = true;
                    // Mark enemy groups so they are forced active later in this same tick,
                    // even if no player is near them.
                    { _forceActiveGroups pushBackUnique (group _x) } forEach _combatEnemies;
                };
            };
        };

        if ((group _unit) getVariable ["AIC_zeusWaypoint", false]
            || _inCombat
            || (group _unit) in _forceActiveGroups) then {
            _inRangeLOS pushBack _unit;
        } else {
```

- [ ] **Step 3: Verify the else branch and closing braces are intact**

The rest of the unit processing (range check, LOS raycast, `_inRangeNoLOS` push) should be unchanged inside the `else` block. Confirm the forEach closes correctly.

- [ ] **Step 4: Build and verify in RPT**

Run `.\build.ps1`. Launch a test mission with `AIC_debug = true`. In the RPT, confirm:
- `[AIC] Active:` lines still appear each tick
- No script errors in the log
- With two enemy AI groups within `AIC_combatRadius` of each other but away from players, both groups should show as active (not culled)

- [ ] **Step 5: Commit**

```bash
git add "@ai_culler/addons/aic_main/functions/fn_mainLoop.sqf"
git commit -m "fix: bidirectional combat activation and behaviour-state supplement in mainLoop"
```

---

## Task 4: Extract waypoint monitor into its own function

**Files:**
- Create: `@ai_culler/addons/aic_main/functions/fn_waypointMonitor.sqf`
- Modify: `@ai_culler/addons/aic_main/functions/fn_postInit.sqf`
- Modify: `@ai_culler/addons/aic_main/config.cpp`

The waypoint detection loop (~65 lines) is embedded inside `fn_postInit.sqf` alongside server loop startup, FPS broadcasting, and Zeus hook init. Extracting it gives each concern its own file.

- [ ] **Step 1: Create `fn_waypointMonitor.sqf`**

Create the file at `@ai_culler/addons/aic_main/functions/fn_waypointMonitor.sqf` with this content — it is the exact waypoint loop currently in `fn_postInit.sqf`, wrapped in a server guard and a comment:

```sqf
// AIC_fnc_waypointMonitor — polls all AI groups for waypoint count changes.
// Zeus-assigned (or script-assigned) waypoints are detected when count exceeds
// the per-group baseline while not in combat. Runs on the server only.
if (!isServer) exitWith {};

// Snapshot editor-placed waypoints per group after mission init
sleep 5;
{
    private _grp = group _x;
    if (_grp getVariable ["AIC_waypointBaseline", -1] < 0) then {
        _grp setVariable ["AIC_waypointBaseline", count (waypoints _grp)];
    };
} forEach (allUnits select { !isPlayer _x && _x isKindOf "CAManBase" });
if (AIC_debug) then { diag_log "[AIC][WP] Baseline snapshot complete"; };

while {true} do {
    sleep AIC_checkInterval;
    private _seen = [];
    {
        private _grp = group _x;
        if !(_grp in _seen) then {
            _seen pushBack _grp;

            if (_grp getVariable ["AIC_waypointBaseline", -1] < 0) then {
                _grp setVariable ["AIC_waypointBaseline", count (waypoints _grp)];
            };

            private _base = _grp getVariable "AIC_waypointBaseline";
            private _cur  = count (waypoints _grp);
            private _inCombat = (units _grp) findIf { behaviour _x == "COMBAT" } != -1;

            if (!_inCombat && _cur > _base) then {
                if (!(_grp getVariable ["AIC_zeusWaypoint", false])) then {
                    if (AIC_debug) then { diag_log format ["[AIC][WP] Zeus waypoint detected on group %1 (cur=%2 base=%3)", _grp, _cur, _base]; };
                    _grp setVariable ["AIC_zeusWaypoint", true, true];
                    private _enabled = [];
                    {
                        if (!(_x getVariable ["AIC_zeusProtected", false]) &&
                            (_x getVariable ["AIC_disabled", false])) then {
                            [_x] call AIC_fnc_enableUnit;
                            _enabled pushBack _x;
                        };
                    } forEach (units _grp);
                    if (_enabled isNotEqualTo []) then {
                        [_enabled] remoteExec ["AIC_fnc_updateUnitLabel", 0];
                    };
                };
            };

            if (_grp getVariable ["AIC_zeusWaypoint", false]) then {
                private _curWP = currentWaypoint _grp;
                if (_cur <= _base || _curWP >= _cur) then {
                    if (AIC_debug) then { diag_log format ["[AIC][WP] Zeus waypoints cleared on group %1 (cur=%2 base=%3 curWP=%4)", _grp, _cur, _base, _curWP]; };
                    _grp setVariable ["AIC_waypointBaseline", _cur];
                    _grp setVariable ["AIC_zeusWaypoint", false, true];
                    [(units _grp)] remoteExec ["AIC_fnc_updateUnitLabel", 0];
                };
            };
        };
    } forEach (allUnits select { !isPlayer _x && _x isKindOf "CAManBase" && alive _x });
};
```

- [ ] **Step 2: Remove the waypoint loop from `fn_postInit.sqf` and replace with a spawn call**

In `fn_postInit.sqf`, find the entire waypoint detection block (the `[] spawn {` block that starts with `// Detect Zeus-assigned waypoints...` and ends with `};` matching that spawn). Delete it and replace with one line:

```sqf
    [] spawn AIC_fnc_waypointMonitor;
```

The server block in `fn_postInit.sqf` should now look like:

```sqf
if (isServer) then {
    if (AIC_debug) then { diag_log "[AIC] Server — starting culler loop"; };
    [] spawn AIC_fnc_mainLoop;

    AIC_serverFPS = round diag_fps;

    [] spawn {
        while {true} do {
            sleep 1;
            AIC_serverFPS = round diag_fps;
            {
                private _player = getAssignedCuratorUnit _x;
                if (!isNull _player) then { (owner _player) publicVariableClient "AIC_serverFPS" };
            } forEach allCurators;
        };
    };

    [] spawn AIC_fnc_waypointMonitor;
};
```

- [ ] **Step 3: Register `fn_waypointMonitor` in `config.cpp`**

In `config.cpp`, inside the `class Main` block, add one entry after `class mainLoop {}`:

```cpp
class mainLoop         {};
class waypointMonitor  {};
```

- [ ] **Step 4: Build and verify**

Run `.\build.ps1`. Launch a test mission. In the RPT confirm:
- `[AIC][WP] Baseline snapshot complete` appears after ~5 seconds
- `[AIC][WP] Zeus waypoint detected` appears when a Zeus move order is given
- `[AIC][WP] Zeus waypoints cleared` appears when the group completes the waypoints

- [ ] **Step 5: Commit**

```bash
git add "@ai_culler/addons/aic_main/functions/fn_waypointMonitor.sqf"
git add "@ai_culler/addons/aic_main/functions/fn_postInit.sqf"
git add "@ai_culler/addons/aic_main/config.cpp"
git commit -m "refactor: extract waypoint monitor loop from postInit into fn_waypointMonitor"
```

---

## Task 5: Add `AIC_lastStats` store to fn_mainLoop.sqf

**Files:**
- Modify: `@ai_culler/addons/aic_main/functions/fn_mainLoop.sqf`

`AIC_fnc_getStats` (created in Task 6) needs somewhere to read from. Store a HashMap each tick just before the `broadcastStats` call.

- [ ] **Step 1: Add the stats store before the broadcastStats call**

Find the existing broadcastStats call near the end of the loop:

```sqf
    [_activeCount, count _inRangeLOS, count _inRangeNoLOS, count _outOfRange, _protectedCount, _culledCount, _overrideCount, _totalAI, AIC_serverFPS]
        call AIC_fnc_broadcastStats;
```

Insert the HashMap store immediately before it:

```sqf
    AIC_lastStats = createHashMapFromArray [
        ["active",    _activeCount],
        ["los",       count _inRangeLOS],
        ["noLos",     count _inRangeNoLOS],
        ["culled",    _culledCount],
        ["protected", _protectedCount],
        ["override",  _overrideCount],
        ["total",     _totalAI],
        ["serverFps", AIC_serverFPS]
    ];

    [_activeCount, count _inRangeLOS, count _inRangeNoLOS, count _outOfRange, _protectedCount, _culledCount, _overrideCount, _totalAI, AIC_serverFPS]
        call AIC_fnc_broadcastStats;
```

- [ ] **Step 2: Commit**

```bash
git add "@ai_culler/addons/aic_main/functions/fn_mainLoop.sqf"
git commit -m "feat: store last tick stats in AIC_lastStats HashMap for public API"
```

---

## Task 6: Create the four public API functions

**Files:**
- Create: `@ai_culler/addons/aic_main/functions/fn_protect.sqf`
- Create: `@ai_culler/addons/aic_main/functions/fn_unprotect.sqf`
- Create: `@ai_culler/addons/aic_main/functions/fn_isCulled.sqf`
- Create: `@ai_culler/addons/aic_main/functions/fn_getStats.sqf`

All four functions are callable from any machine. `fn_protect` and `fn_unprotect` automatically forward to the server if called from a client. `fn_isCulled` and `fn_getStats` read broadcast variables and can be called anywhere.

- [ ] **Step 1: Create `fn_protect.sqf`**

```sqf
// AIC_fnc_protect — exclude a unit from the culler permanently.
// Safe to call from any machine; forwards to server automatically if needed.
// Example: [myUnit] call AIC_fnc_protect;
params [["_unit", objNull, [objNull]]];
if (isNull _unit || !(_unit isKindOf "CAManBase")) exitWith {};
if (!isServer) exitWith { [_unit] remoteExec ["AIC_fnc_protect", 2] };
_unit setVariable ["AIC_zeusProtected", true, true];
[_unit] remoteExec ["AIC_fnc_updateUnitLabel", 0];
if (AIC_debug) then { diag_log format ["[AIC][API] Unit protected: %1", _unit] };
```

- [ ] **Step 2: Create `fn_unprotect.sqf`**

```sqf
// AIC_fnc_unprotect — return a previously protected unit to the culler pool.
// Safe to call from any machine; forwards to server automatically if needed.
// Example: [myUnit] call AIC_fnc_unprotect;
params [["_unit", objNull, [objNull]]];
if (isNull _unit || !(_unit isKindOf "CAManBase")) exitWith {};
if (!isServer) exitWith { [_unit] remoteExec ["AIC_fnc_unprotect", 2] };
_unit setVariable ["AIC_zeusProtected", false, true];
[_unit] remoteExec ["AIC_fnc_updateUnitLabel", 0];
if (AIC_debug) then { diag_log format ["[AIC][API] Unit unprotected: %1", _unit] };
```

- [ ] **Step 3: Create `fn_isCulled.sqf`**

```sqf
// AIC_fnc_isCulled — returns true if the unit's simulation is currently disabled.
// Reads a globally broadcast variable — callable from any machine.
// Example: if ([myUnit] call AIC_fnc_isCulled) then { ... };
params [["_unit", objNull, [objNull]]];
if (isNull _unit) exitWith { false };
_unit getVariable ["AIC_disabled", false]
```

- [ ] **Step 4: Create `fn_getStats.sqf`**

```sqf
// AIC_fnc_getStats — returns the last tick's culler stats as a HashMap.
// Updated once per culler tick (default every 5s). Returns empty HashMap
// before the first tick completes. Callable from any machine.
//
// Keys: "active", "los", "noLos", "culled", "protected", "override",
//       "total", "serverFps"
//
// Example:
//   private _stats = [] call AIC_fnc_getStats;
//   private _active = _stats getOrDefault ["active", 0];
if (isNil "AIC_lastStats") exitWith { createHashMap };
AIC_lastStats
```

- [ ] **Step 5: Commit**

```bash
git add "@ai_culler/addons/aic_main/functions/fn_protect.sqf"
git add "@ai_culler/addons/aic_main/functions/fn_unprotect.sqf"
git add "@ai_culler/addons/aic_main/functions/fn_isCulled.sqf"
git add "@ai_culler/addons/aic_main/functions/fn_getStats.sqf"
git commit -m "feat: add public API functions (protect, unprotect, isCulled, getStats)"
```

---

## Task 7: Register the new functions in config.cpp

**Files:**
- Modify: `@ai_culler/addons/aic_main/config.cpp`

- [ ] **Step 1: Add four API entries and the waypointMonitor entry to `class Main`**

Find the `class Main` block. Add the five new entries. The full updated class should look like:

```cpp
class Main {
    file = "aic_main\functions";
    class preInit           { preInit  = 1; };
    class postInit          { postInit = 1; };
    class registerSettings  {};
    class mainLoop         {};
    class waypointMonitor  {};
    class enableUnit       {};
    class disableUnit      {};
    class getCullDist      {};
    class broadcastStats   {};
    class toggleProtection {};
    class initZeusHooks    {};
    class createStatusWindow {};
    class updateStatusWindow {};
    class setCullerEnabled  {};
    class applySettings     {};
    class updateUnitLabel      {};
    class createFpsGraphPanel  {};
    class renderFpsGraph       {};
    class protect          {};
    class unprotect        {};
    class isCulled         {};
    class getStats         {};
};
```

- [ ] **Step 2: Build**

Run `.\build.ps1`. Confirm no build errors.

- [ ] **Step 3: Verify API functions are accessible in-game**

Launch a test mission. In the debug console run:
```sqf
diag_log str ([] call AIC_fnc_getStats);
```
The RPT should show a HashMap string like `[["active",12],["los",8],...]` after the first culler tick.

Then run:
```sqf
[vehicle player] call AIC_fnc_protect;
```
Confirm no error and that the unit's label updates.

- [ ] **Step 4: Commit**

```bash
git add "@ai_culler/addons/aic_main/config.cpp"
git commit -m "chore: register waypointMonitor and four public API functions in config.cpp"
```

---

## Task 8: Write the API documentation

**Files:**
- Create: `docs/API.md`
- Modify: `README.md`

- [ ] **Step 1: Create `docs/API.md`**

Create the file at `docs/API.md`:

```markdown
# AI Culler — Public API

These functions are part of AI Culler's stable public interface. They are safe to call from mission scripts, framework mods (Antistasi, ALIVE, etc.), and other addons. Internal functions prefixed with `AIC_fnc_` that are not listed here are implementation details and may change between versions.

---

## AIC_fnc_protect

Exclude a unit from the culler permanently. The unit will always be simulated regardless of distance or player LOS. Equivalent to right-clicking **Toggle Culler Protection** in Zeus.

**Callable from:** Any machine (automatically forwarded to server)

**Parameters:**
- `_unit` — Object — The AI unit to protect. Must be a `CAManBase` infantry unit.

**Returns:** Nothing

**Example:**
```sqf
[mySquadLeader] call AIC_fnc_protect;
```

**Notes:**
- Has no effect on players, vehicles, or vehicle crew.
- Protection persists until `AIC_fnc_unprotect` is called or the mission ends.
- Protected units are visible in the Zeus status window and carry the `[Protected]` 3D label.

---

## AIC_fnc_unprotect

Return a previously protected unit to the normal culling pool.

**Callable from:** Any machine (automatically forwarded to server)

**Parameters:**
- `_unit` — Object — The AI unit to unprotect.

**Returns:** Nothing

**Example:**
```sqf
[mySquadLeader] call AIC_fnc_unprotect;
```

---

## AIC_fnc_isCulled

Returns whether a unit's simulation is currently disabled by the culler.

**Callable from:** Any machine

**Parameters:**
- `_unit` — Object — The AI unit to query.

**Returns:** Boolean — `true` if the unit is currently culled, `false` otherwise.

**Example:**
```sqf
if ([myUnit] call AIC_fnc_isCulled) then {
    hint "This unit is currently culled";
};
```

**Notes:**
- Returns `false` for protected units, players, and units not managed by the culler.
- The value reflects the state as of the last culler tick (default every 5 seconds).

---

## AIC_fnc_getStats

Returns the culler's stats from the most recent tick as a HashMap.

**Callable from:** Any machine

**Parameters:** None

**Returns:** HashMap with the following keys:

| Key | Type | Description |
|---|---|---|
| `"active"` | Number | Total units currently simulating |
| `"los"` | Number | Units active because a player has LOS |
| `"noLos"` | Number | Units active due to proximity but no LOS |
| `"culled"` | Number | Units with simulation disabled |
| `"protected"` | Number | Units excluded from culling entirely |
| `"override"` | Number | Units active due to Zeus/script waypoint |
| `"total"` | Number | All managed AI (protected + pool) |
| `"serverFps"` | Number | Server FPS at last tick |

Returns an empty HashMap before the first culler tick completes.

**Example:**
```sqf
private _stats = [] call AIC_fnc_getStats;
private _active = _stats getOrDefault ["active", 0];
private _culled = _stats getOrDefault ["culled", 0];
hint format ["Active: %1 | Culled: %2", _active, _culled];
```

---

## Internal variables (read-only, may change)

These variables are set globally and can be read by other scripts, but should not be written to directly — use the API functions instead.

| Variable | Set on | Description |
|---|---|---|
| `AIC_disabled` | Unit (global) | `true` if unit simulation is currently off |
| `AIC_zeusProtected` | Unit (global) | `true` if unit is protected from culling |
| `AIC_zeusWaypoint` | Group (global) | `true` if group has an active waypoint override |
| `AIC_lastStats` | Namespace (server) | HashMap of last tick stats (see AIC_fnc_getStats) |
```

- [ ] **Step 2: Add an API section to `README.md`**

Find the `## Compatibility` section header in `README.md`. Insert a new section immediately before it:

```markdown
## Scripting API

AI Culler exposes a small public API for mission scripts, frameworks, and other mods. All functions are safe to call from any machine — server forwarding is handled automatically.

| Function | Description |
|---|---|
| `[unit] call AIC_fnc_protect` | Exclude a unit from culling permanently |
| `[unit] call AIC_fnc_unprotect` | Return a unit to the culling pool |
| `[unit] call AIC_fnc_isCulled` | Returns `true` if the unit is currently culled |
| `[] call AIC_fnc_getStats` | Returns last tick stats as a HashMap |

Full documentation: [docs/API.md](docs/API.md)

### Quick example — protect a unit from a mission script

```sqf
// Protect a specific unit so it is never culled
[myHVT] call AIC_fnc_protect;

// Check state
if ([myHVT] call AIC_fnc_isCulled) then {
    diag_log "HVT was culled — something went wrong";
};

// Read live stats
private _stats = [] call AIC_fnc_getStats;
hint format ["Server running %1 active AI", _stats getOrDefault ["active", 0]];
```

```

- [ ] **Step 3: Commit**

```bash
git add "docs/API.md" "README.md"
git commit -m "docs: add public API reference (docs/API.md) and README scripting section"
```

---

## Task 9: Final build, version bump, and push

- [ ] **Step 1: Update version in both `config.cpp` files**

In `@ai_culler/addons/aic_main/config.cpp`:
```cpp
version = "1.1.0";
versionStr = "1.1.0";
versionAr[] = {1, 1, 0};
```

In `@ai_culler/addons/aic_client/config.cpp`:
```cpp
version = "1.1.0";
versionStr = "1.1.0";
versionAr[] = {1, 1, 0};
```

- [ ] **Step 2: Add v3.6.0 changelog entry to `README.md`**

Add before the `### v3.5.0` entry:

```markdown
### v3.6.0
- Performance: `allUnits` is now snapshotted once per tick in the main loop (was called 4 separate times — one per filter/count operation)
- Performance: combat detection array (`_forceActiveGroups`) built incrementally per unit, eliminating a redundant per-unit data structure rebuild
- Fix: combat activation is now bidirectional — when unit A detects unit B as an enemy, both groups are forced active. Previously only the detecting side was guaranteed to activate
- Fix: units in `"COMBAT"` behaviour are now kept active even when no enemy is within `AIC_combatRadius` — covers units still engaged after the enemy has moved away
- Refactor: waypoint monitor extracted from `fn_postInit.sqf` into its own `fn_waypointMonitor.sqf`
- Refactor: removed dead `fn_registerSettings` call from `fn_preInit.sqf` (CBA wiped it immediately — registration already happens correctly in `fn_postInit.sqf`)
- Added public scripting API: `AIC_fnc_protect`, `AIC_fnc_unprotect`, `AIC_fnc_isCulled`, `AIC_fnc_getStats` — callable from any machine, safe for use by mission scripts and framework mods
- Added `docs/API.md` with full API reference
```

- [ ] **Step 3: Run final build**

```
.\build.ps1
```

Confirm both PBOs build and sign without errors.

- [ ] **Step 4: Final commit and push**

```bash
git add "@ai_culler/addons/aic_main/config.cpp"
git add "@ai_culler/addons/aic_client/config.cpp"
git add "README.md"
git commit -m "chore: bump version to 1.1.0 / v3.6.0 and update changelog"
git push
```

---

## Self-Review

**Spec coverage check:**
- ✅ Single allUnits snapshot — Task 1
- ✅ Dead preInit cleanup — Task 2
- ✅ Bidirectional combat + behaviour check — Task 3
- ✅ AIC_lastStats store — Task 5
- ✅ Waypoint monitor extraction — Task 4
- ✅ Public API functions — Task 6
- ✅ config.cpp registration — Task 7
- ✅ API documentation — Task 8
- ✅ README update + version bump — Task 9

**Placeholder scan:** No TBDs or incomplete sections found.

**Type consistency:**
- `AIC_lastStats` defined in Task 5 (fn_mainLoop.sqf), read in Task 6 (fn_getStats.sqf) — consistent
- `AIC_fnc_protect`/`AIC_fnc_unprotect` call `AIC_fnc_updateUnitLabel` — already exists in config.cpp
- `AIC_fnc_waypointMonitor` registered in Task 7 config.cpp, created in Task 4 — consistent
- All four API functions registered in Task 7, created in Task 6 — consistent
