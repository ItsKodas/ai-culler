# AI Culler — Settings Panel Design Spec
**Date:** 2026-06-14

## Overview

Add an inline "⚙ Settings" toggle button to the existing Zeus status window that expands a sub-section of editable fields, letting Zeus operators adjust culling settings mid-op without rebuilding the PBO.

---

## 1. Panel Layout

The Settings button sits below the existing Enable/Disable Culler button. Clicking it toggles a settings sub-section below:

```
┌─ AI Culler ──────────[▲]─┐
│  Active     74 / 80       │
│  LOS          12          │
│  No-LOS       62          │
│  Culled       45          │
│  Protected     8          │
│  [Disable Culler]         │  IDC 9208 (existing)
│  [⚙ Settings]            │  IDC 9209 (new toggle)
│  Max AI:      [80   ]     │  IDC 9210 (label) / 9211 (edit)
│  Dist OPFOR:  [1000 ]     │  IDC 9212 (label) / 9213 (edit)
│  Dist Indep:  [800  ]     │  IDC 9214 (label) / 9215 (edit)
│  Dist Civ:    [400  ]     │  IDC 9216 (label) / 9217 (edit)
│  Interval(s): [5    ]     │  IDC 9218 (label) / 9219 (edit)
│  [Apply]                  │  IDC 9220
└───────────────────────────┘
```

When the settings sub-section is hidden, the window shows 7 rows (5 stat rows + Enable/Disable button + Settings button). Collapsed state (via the ▲/▼ button) hides everything except the title bar — unchanged from existing behavior.

---

## 2. IDC Allocation

| IDC  | Control        | Purpose                        |
|------|----------------|--------------------------------|
| 9200 | RscText        | Background (existing)          |
| 9201 | RscText        | Title "AI Culler" (existing)   |
| 9202 | RscButton      | Collapse ▲/▼ (existing)        |
| 9203 | RscText        | "Active: X / Y" (existing)     |
| 9204 | RscText        | "LOS: X" (existing)            |
| 9205 | RscText        | "No-LOS: X" (existing)         |
| 9206 | RscText        | "Culled: X" (existing)         |
| 9207 | RscText        | "Protected: X" (existing)      |
| 9208 | RscButton      | Enable/Disable culler (existing)|
| 9209 | RscButton      | ⚙ Settings toggle (new)        |
| 9210 | RscText        | "Max AI:" label (new)          |
| 9211 | RscEdit        | Max active AI input (new)      |
| 9212 | RscText        | "Dist OPFOR:" label (new)      |
| 9213 | RscEdit        | OPFOR distance input (new)     |
| 9214 | RscText        | "Dist Indep:" label (new)      |
| 9215 | RscEdit        | Independent distance input (new)|
| 9216 | RscText        | "Dist Civ:" label (new)        |
| 9217 | RscEdit        | Civilian distance input (new)  |
| 9218 | RscText        | "Interval(s):" label (new)     |
| 9219 | RscEdit        | Check interval input (new)     |
| 9220 | RscButton      | Apply button (new)             |

---

## 3. Interaction Behaviour

### Settings toggle (IDC 9209)
- Starts hidden/closed when status window opens.
- Clicking toggles a local `AIC_settingsOpen` variable on the button.
- When opened: IDC 9210–9220 become visible; edit fields (9211, 9213, 9215, 9217, 9219) are prefilled with current global values (`AIC_maxActiveAI`, `AIC_distOpfor`, `AIC_distIndependent`, `AIC_distCivilian`, `AIC_checkInterval`); background height grows to accommodate 6 extra rows.
- When closed: IDC 9210–9220 are hidden; background shrinks back.

### Collapse button (IDC 9202)
- Existing behaviour unchanged: collapses everything except the title bar.
- The collapsed IDC list expands from `[9203..9208]` to `[9203..9209]` (Settings button also hidden when collapsed; 9210–9220 are already hidden unless settings were open).
- Exact list to hide: `[9203,9204,9205,9206,9207,9208,9209,9210,9211,9212,9213,9214,9215,9216,9217,9218,9219,9220]`.
- Background height logic also unchanged — collapsed height shows title bar only.

### Apply button (IDC 9220)
- Reads `ctrlText` from IDC 9211, 9213, 9215, 9217, 9219.
- Converts to integers with `parseNumber`.
- `remoteExec`s `AIC_fnc_applySettings` to the server (machine 2) with params `[maxAI, distOpfor, distIndep, distCiv, interval]`.
- No local feedback beyond the next stats tick reflecting the new `AIC_maxActiveAI` value in the "Active" row.

---

## 4. Server-Side: `fnc_applySettings.sqf`

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

---

## 5. Files Changed

| File | Change |
|------|--------|
| `functions/fnc_createStatusWindow.sqf` | Add IDC 9209 Settings button + IDC 9210–9220 settings sub-section with toggle logic |
| `functions/fnc_applySettings.sqf` | New — server-side, updates 5 globals and publicVariable each |
| `config.cpp` | Add `class applySettings {};` in CfgFunctions |

`fnc_updateStatusWindow.sqf` requires no changes — the settings fields show current globals when the section is opened, not on every stats tick.

---

## 6. Out of Scope

- Input validation beyond `parseNumber` (garbage input silently becomes 0 — acceptable for internal Zeus tooling)
- Persisting settings across server restarts
- `AIC_debug` toggle (boolean, not numeric — excluded to keep the UI uniform; it can still be set in `fnc_preInit.sqf`)
