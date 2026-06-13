# Settings Panel Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an inline "Settings" button to the AI Culler Zeus status window that expands editable fields for the five culling globals, letting Zeus operators change them mid-op without rebuilding the PBO.

**Architecture:** Three coordinated changes — register the new function in CfgFunctions, create the server-side `fnc_applySettings.sqf` that updates globals and broadcasts them, then rewrite `fnc_createStatusWindow.sqf` to add IDC 9209 (Settings toggle) and IDCs 9210–9220 (sub-section controls). The sub-section mirrors the existing collapse pattern: hidden by default, shown/hidden by toggling a local variable on the button control, with background height updated to match.

**Tech Stack:** Arma 3 SQF scripting, Arma addon PBO structure. No external dependencies. No automated test framework exists for SQF — verification is manual in-game.

---

## File Map

| File | Action | Purpose |
|------|--------|---------|
| `@ai_culler/addons/aic_main/config.cpp` | Modify | Register `applySettings` in CfgFunctions |
| `@ai_culler/addons/aic_main/functions/fnc_applySettings.sqf` | Create | Server-side: update 5 globals + publicVariable each |
| `@ai_culler/addons/aic_main/functions/fnc_createStatusWindow.sqf` | Modify | Add Settings button, sub-section controls, updated collapse handler |

`fnc_updateStatusWindow.sqf`, `fnc_preInit.sqf`, and all other files are **unchanged**.

---

## IDC Reference

| IDC range | Owner |
|-----------|-------|
| 9200–9208 | Existing status window controls (background, title, collapse btn, stat rows, enable/disable btn) |
| 9209 | Settings toggle button (new) |
| 9210 / 9211 | "Max AI:" label / edit field (new) |
| 9212 / 9213 | "Dist OPFOR:" label / edit field (new) |
| 9214 / 9215 | "Dist Indep:" label / edit field (new) |
| 9216 / 9217 | "Dist Civ:" label / edit field (new) |
| 9218 / 9219 | "Interval(s):" label / edit field (new) |
| 9220 | Apply button (new) |

---

### Task 1: Register `applySettings` in CfgFunctions

**Files:**
- Modify: `@ai_culler/addons/aic_main/config.cpp` (line 30)

The CfgFunctions `class Main` block must declare every function the mod auto-loads. Without this entry, Arma will not compile `fnc_applySettings.sqf` and `AIC_fnc_applySettings` will be undefined.

- [ ] **Step 1: Add the class entry**

Open `@ai_culler/addons/aic_main/config.cpp`. Find the line:

```cpp
            class setCullerEnabled {};
```

Add the new entry directly after it:

```cpp
            class setCullerEnabled {};
            class applySettings     {};
```

The full `class Main` block should now read:

```cpp
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
            class setCullerEnabled {};
            class applySettings    {};
        };
```

- [ ] **Step 2: Commit**

```bash
git add "@ai_culler/addons/aic_main/config.cpp"
git commit -m "feat: register AIC_fnc_applySettings in CfgFunctions"
```

---

### Task 2: Create `fnc_applySettings.sqf`

**Files:**
- Create: `@ai_culler/addons/aic_main/functions/fnc_applySettings.sqf`

This function runs on the **server only**. It receives five numeric params sent via `remoteExecCall` from the Zeus client Apply button, updates all five culling globals, broadcasts each with `publicVariable` so other Zeus clients stay in sync, and logs in debug mode.

The server guard (`if !(isServer) exitWith {};`) is redundant when called via `remoteExecCall ["AIC_fnc_applySettings", 2]` (machine 2 = server), but is included as a safety net matching the convention in `fnc_mainLoop.sqf`.

- [ ] **Step 1: Create the file with this exact content**

```sqf
if !(isServer) exitWith {};
params ["_maxAI", "_distOpfor", "_distIndep", "_distCiv", "_interval"];

AIC_maxActiveAI     = _maxAI;
AIC_distOpfor       = _distOpfor;
AIC_distIndependent = _distIndep;
AIC_distCivilian    = _distCiv;
AIC_checkInterval   = _interval;

publicVariable "AIC_maxActiveAI";
publicVariable "AIC_distOpfor";
publicVariable "AIC_distIndependent";
publicVariable "AIC_distCivilian";
publicVariable "AIC_checkInterval";

if (AIC_debug) then {
    diag_log format ["[AIC] Settings applied — maxAI:%1 distO:%2 distI:%3 distC:%4 interval:%5",
        _maxAI, _distOpfor, _distIndep, _distCiv, _interval];
};
```

- [ ] **Step 2: Commit**

```bash
git add "@ai_culler/addons/aic_main/functions/fnc_applySettings.sqf"
git commit -m "feat: add AIC_fnc_applySettings — update culling globals mid-op"
```

---

### Task 3: Update `fnc_createStatusWindow.sqf`

**Files:**
- Modify: `@ai_culler/addons/aic_main/functions/fnc_createStatusWindow.sqf`

This is a full rewrite of the file. Key changes from the existing version:

1. **Cleanup line** — extends the IDC list from `[9200..9208]` to `[9200..9220]`.
2. **Background height** — changes from `_tH + (_rH * 6) + 0.012` (6 rows) to `_tH + (_rH * 7) + 0.012` (7 rows, adding the Settings button row). Settings-open state further extends to `_tH + (_rH * 13) + 0.012`.
3. **Collapse handler** — replaces the simple `ctrlShow !_collapse` forEach with two-branch logic: collapse hides everything; expand always shows 9203–9209 and conditionally shows 9210–9220 based on `AIC_settingsOpen` stored on button 9209.
4. **Settings toggle button (9209)** — row 6, below Enable/Disable. Stores `AIC_settingsOpen` local variable. On click: prefills edit fields from current globals when opening, shows/hides 9210–9220, resizes background.
5. **Settings sub-section (9210–9219)** — created via a `forEach` over a definition array `[["label", labelIDC, editIDC], ...]`. All start hidden (`ctrlShow false`). Edit fields are `RscEdit` type, prefilled with `""` initially.
6. **Apply button (9220)** — row 12, starts hidden. On click: reads `ctrlText` from IDC 9211/9213/9215/9217/9219, converts with `parseNumber`, calls `remoteExecCall ["AIC_fnc_applySettings", 2]`.

**Layout arithmetic:**
- `_tH = 0.036`, `_rH = 0.033`
- Stats rows 0–4: `_y + _tH + 0.006 + (_rH * 0..4)`
- Enable/Disable (9208): row 5
- Settings toggle (9209): row 6
- Settings rows (9210–9219): rows 7–11
- Apply (9220): row 12
- Background height with settings open: `0.036 + (0.033 × 13) + 0.012 = 0.477`
- Background height with settings closed: `0.036 + (0.033 × 7) + 0.012 = 0.279`

**Label/edit split:** `_lW = 0.135` (label), gap `0.004`, `_eW = 0.102` (edit), right margin `0.007`. Total = 0.135 + 0.004 + 0.102 + 0.007 + 0.007 = 0.255 = `_w`. ✓

- [ ] **Step 1: Replace the entire file with this content**

```sqf
params ["_display"];

if (isNull _display) exitWith {};

// Remove existing controls (idempotent)
{ ctrlDelete (_display displayCtrl _x); } forEach [9200,9201,9202,9203,9204,9205,9206,9207,9208,9209,9210,9211,9212,9213,9214,9215,9216,9217,9218,9219,9220];

private _wx = safeZoneX + safeZoneW - 0.265;
private _y  = safeZoneY + 0.025;
private _w  = 0.255;
private _rH = 0.033;
private _tH = 0.036;

// Background — 7 rows when settings closed, 13 when settings open
private _bg = _display ctrlCreate ["RscText", 9200];
_bg ctrlSetPosition [_wx, _y, _w, _tH + (_rH * 7) + 0.012];
_bg ctrlSetBackgroundColor [0, 0, 0, 0.78];
_bg ctrlCommit 0;

// Title
private _title = _display ctrlCreate ["RscText", 9201];
_title ctrlSetPosition [_wx + 0.005, _y + 0.003, _w - 0.045, _tH - 0.006];
_title ctrlSetText "AI Culler";
_title ctrlSetBackgroundColor [0.12, 0.12, 0.12, 1];
_title ctrlCommit 0;

// Collapse/expand button
private _collapseBtn = _display ctrlCreate ["RscButton", 9202];
_collapseBtn ctrlSetPosition [_wx + _w - 0.042, _y + 0.002, 0.037, _tH - 0.004];
_collapseBtn ctrlSetText "▲";
_collapseBtn ctrlCommit 0;
_collapseBtn setVariable ["AIC_collapsed", false];

_collapseBtn ctrlAddEventHandler ["ButtonClick", {
    params ["_btn"];
    private _disp     = ctrlParent _btn;
    private _collapse = !(_btn getVariable ["AIC_collapsed", false]);
    _btn setVariable ["AIC_collapsed", _collapse];
    _btn ctrlSetText if (_collapse) then {"▼"} else {"▲"};
    _btn ctrlCommit 0;

    if (_collapse) then {
        { (_disp displayCtrl _x) ctrlShow false; (_disp displayCtrl _x) ctrlCommit 0; }
            forEach [9203,9204,9205,9206,9207,9208,9209,9210,9211,9212,9213,9214,9215,9216,9217,9218,9219,9220];
    } else {
        { (_disp displayCtrl _x) ctrlShow true; (_disp displayCtrl _x) ctrlCommit 0; }
            forEach [9203,9204,9205,9206,9207,9208,9209];
        if ((_disp displayCtrl 9209) getVariable ["AIC_settingsOpen", false]) then {
            { (_disp displayCtrl _x) ctrlShow true; (_disp displayCtrl _x) ctrlCommit 0; }
                forEach [9210,9211,9212,9213,9214,9215,9216,9217,9218,9219,9220];
        };
    };

    private _bg2      = _disp displayCtrl 9200;
    private _pos      = ctrlPosition _bg2;
    private _tH2      = 0.036;
    private _rH2      = 0.033;
    private _sOpen    = (_disp displayCtrl 9209) getVariable ["AIC_settingsOpen", false];
    _bg2 ctrlSetPosition [
        _pos select 0, _pos select 1, _pos select 2,
        if (_collapse) then {
            _tH2 + 0.004
        } else {
            if (_sOpen) then {_tH2 + (_rH2 * 13) + 0.012} else {_tH2 + (_rH2 * 7) + 0.012}
        }
    ];
    _bg2 ctrlCommit 0;
}];

// Stat row labels (rows 0–4)
private _labels = ["Active: -- / --", "LOS: --", "No-LOS: --", "Culled: --", "Protected: --"];
private _idcs   = [9203, 9204, 9205, 9206, 9207];

{
    private _ctrl = _display ctrlCreate ["RscText", _idcs select _forEachIndex];
    _ctrl ctrlSetPosition [_wx + 0.007, _y + _tH + 0.006 + (_rH * _forEachIndex), _w - 0.014, _rH - 0.004];
    _ctrl ctrlSetText _x;
    _ctrl ctrlCommit 0;
} forEach _labels;

// Enable/Disable culler toggle button (row 5)
private _toggleBtn = _display ctrlCreate ["RscButton", 9208];
_toggleBtn ctrlSetPosition [_wx + 0.007, _y + _tH + 0.006 + (_rH * 5), _w - 0.014, _rH - 0.004];
_toggleBtn ctrlSetText if (AIC_cullerEnabled) then {"Disable Culler"} else {"Enable Culler"};
_toggleBtn ctrlCommit 0;

_toggleBtn ctrlAddEventHandler ["ButtonClick", {
    params ["_btn"];
    private _newState = !AIC_cullerEnabled;
    [_newState] remoteExecCall ["AIC_fnc_setCullerEnabled", 2];
    _btn ctrlSetText if (_newState) then {"Disable Culler"} else {"Enable Culler"};
    _btn ctrlCommit 0;
}];

// Settings toggle button (row 6)
private _settingsToggle = _display ctrlCreate ["RscButton", 9209];
_settingsToggle ctrlSetPosition [_wx + 0.007, _y + _tH + 0.006 + (_rH * 6), _w - 0.014, _rH - 0.004];
_settingsToggle ctrlSetText "Settings";
_settingsToggle ctrlCommit 0;
_settingsToggle setVariable ["AIC_settingsOpen", false];

_settingsToggle ctrlAddEventHandler ["ButtonClick", {
    params ["_btn"];
    private _disp = ctrlParent _btn;
    private _open = !(_btn getVariable ["AIC_settingsOpen", false]);
    _btn setVariable ["AIC_settingsOpen", _open];

    if (_open) then {
        (_disp displayCtrl 9211) ctrlSetText str AIC_maxActiveAI;
        (_disp displayCtrl 9213) ctrlSetText str AIC_distOpfor;
        (_disp displayCtrl 9215) ctrlSetText str AIC_distIndependent;
        (_disp displayCtrl 9217) ctrlSetText str AIC_distCivilian;
        (_disp displayCtrl 9219) ctrlSetText str AIC_checkInterval;
    };

    { (_disp displayCtrl _x) ctrlShow _open; (_disp displayCtrl _x) ctrlCommit 0; }
        forEach [9210,9211,9212,9213,9214,9215,9216,9217,9218,9219,9220];

    private _bg3  = _disp displayCtrl 9200;
    private _pos3 = ctrlPosition _bg3;
    private _tH3  = 0.036;
    private _rH3  = 0.033;
    _bg3 ctrlSetPosition [
        _pos3 select 0, _pos3 select 1, _pos3 select 2,
        if (_open) then {_tH3 + (_rH3 * 13) + 0.012} else {_tH3 + (_rH3 * 7) + 0.012}
    ];
    _bg3 ctrlCommit 0;
}];

// Settings sub-section — label + edit pairs, rows 7–11 (initially hidden)
private _settingsDefs = [
    ["Max AI:",      9210, 9211],
    ["Dist OPFOR:",  9212, 9213],
    ["Dist Indep:",  9214, 9215],
    ["Dist Civ:",    9216, 9217],
    ["Interval(s):", 9218, 9219]
];
private _lW = 0.135;
private _eX = _wx + 0.007 + _lW + 0.004;
private _eW = _w - 0.007 - _lW - 0.004 - 0.007;

{
    _x params ["_lbl", "_lIDC", "_eIDC"];
    private _rowY = _y + _tH + 0.006 + (_rH * (_forEachIndex + 7));

    private _lblCtrl = _display ctrlCreate ["RscText", _lIDC];
    _lblCtrl ctrlSetPosition [_wx + 0.007, _rowY, _lW, _rH - 0.004];
    _lblCtrl ctrlSetText _lbl;
    _lblCtrl ctrlCommit 0;
    _lblCtrl ctrlShow false;
    _lblCtrl ctrlCommit 0;

    private _edtCtrl = _display ctrlCreate ["RscEdit", _eIDC];
    _edtCtrl ctrlSetPosition [_eX, _rowY, _eW, _rH - 0.004];
    _edtCtrl ctrlSetText "";
    _edtCtrl ctrlCommit 0;
    _edtCtrl ctrlShow false;
    _edtCtrl ctrlCommit 0;
} forEach _settingsDefs;

// Apply button (row 12, initially hidden)
private _applyBtn = _display ctrlCreate ["RscButton", 9220];
_applyBtn ctrlSetPosition [_wx + 0.007, _y + _tH + 0.006 + (_rH * 12), _w - 0.014, _rH - 0.004];
_applyBtn ctrlSetText "Apply";
_applyBtn ctrlCommit 0;
_applyBtn ctrlShow false;
_applyBtn ctrlCommit 0;

_applyBtn ctrlAddEventHandler ["ButtonClick", {
    params ["_btn"];
    private _disp     = ctrlParent _btn;
    private _maxAI    = parseNumber ctrlText (_disp displayCtrl 9211);
    private _distO    = parseNumber ctrlText (_disp displayCtrl 9213);
    private _distI    = parseNumber ctrlText (_disp displayCtrl 9215);
    private _distC    = parseNumber ctrlText (_disp displayCtrl 9217);
    private _interval = parseNumber ctrlText (_disp displayCtrl 9219);
    [_maxAI, _distO, _distI, _distC, _interval] remoteExecCall ["AIC_fnc_applySettings", 2];
}];
```

- [ ] **Step 2: In-game verification checklist**

Pack the PBO, launch Arma 3 with `@ai_culler`, open an editor mission as Zeus.

  - Status window appears in top-right when Zeus opens. Shows 7 rows (5 stats + Disable Culler + Settings).
  - Collapse (▲) hides all rows — only title bar remains. Expand (▼) restores all 7 rows.
  - Click **Settings** — window expands to show 5 label+edit rows prefilled with current globals (80, 1000, 800, 400, 5) and Apply button.
  - Click **Settings** again — sub-section hides, window shrinks back to 7 rows.
  - Open Settings, collapse (▲), expand (▼) — Settings sub-section is still visible (state preserved).
  - Edit "Max AI:" field to `40`, click Apply. Next culler tick: "Active" row reflects new cap.
  - In RPT log, confirm `[AIC] Settings applied — maxAI:40 distO:1000 distI:800 distC:400 interval:5`.

- [ ] **Step 3: Commit**

```bash
git add "@ai_culler/addons/aic_main/functions/fnc_createStatusWindow.sqf"
git commit -m "feat: add Settings panel to Zeus status window (IDC 9209-9220)"
```
