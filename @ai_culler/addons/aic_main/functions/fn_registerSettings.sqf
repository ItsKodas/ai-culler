// AIC_fnc_registerSettings — registers all CBA Addon Options settings.
// Called from fn_preInit so variables are set before any other code reads them.
// Exits silently if CBA_A3 is not loaded; fn_preInit then applies hard-coded defaults.
if (isNil "CBA_fnc_addSetting") exitWith {};

// ── SERVER SETTINGS ────────────────────────────────────────────────────────
// isGlobal = true: server's Addon Options value is broadcast to all clients.
// Zeus runtime adjustments (Apply button) still override these mid-mission.

[
    "AIC_cullerEnabled", "CHECKBOX", true,
    ["AI Culler", "Enable Culler on Start"],
    "Start the mission with the AI culling system active.",
    true, {}
] call CBA_fnc_addSetting;

[
    "AIC_maxActiveAI", "SLIDER", [200, 10, 500, 0],
    ["AI Culler", "Max Active AI"],
    "Maximum number of AI units the culler allows to be active simultaneously.",
    true, {}
] call CBA_fnc_addSetting;

[
    "AIC_distBlufor", "SLIDER", [2000, 100, 8000, 0],
    ["AI Culler", "BLUFOR Cull Distance (m)"],
    "Distance beyond which BLUFOR AI infantry are culled.",
    true, {}
] call CBA_fnc_addSetting;

[
    "AIC_distOpfor", "SLIDER", [2000, 100, 8000, 0],
    ["AI Culler", "OPFOR Cull Distance (m)"],
    "Distance beyond which OPFOR AI infantry are culled.",
    true, {}
] call CBA_fnc_addSetting;

[
    "AIC_distIndependent", "SLIDER", [2000, 100, 8000, 0],
    ["AI Culler", "Independent Cull Distance (m)"],
    "Distance beyond which Independent AI infantry are culled.",
    true, {}
] call CBA_fnc_addSetting;

[
    "AIC_distCivilian", "SLIDER", [500, 0, 3000, 0],
    ["AI Culler", "Civilian Cull Distance (m)"],
    "Distance beyond which Civilian AI are culled. Set to 0 to always cull civilians.",
    true, {}
] call CBA_fnc_addSetting;

[
    "AIC_checkInterval", "SLIDER", [5, 1, 30, 0],
    ["AI Culler", "Check Interval (s)"],
    "How often (in seconds) the culler re-evaluates all AI units.",
    true, {}
] call CBA_fnc_addSetting;

[
    "AIC_minActiveRadius", "SLIDER", [200, 25, 1000, 0],
    ["AI Culler", "Min Active Radius (m)"],
    "AI within this distance of any player are always active, skipping the LOS check.",
    true, {}
] call CBA_fnc_addSetting;

[
    "AIC_combatRadius", "SLIDER", [400, 50, 1500, 0],
    ["AI Culler", "Combat Detection Radius (m)"],
    "Radius used to detect whether AI units are in active combat with each other.",
    true, {}
] call CBA_fnc_addSetting;

[
    "AIC_debug", "CHECKBOX", false,
    ["AI Culler", "Debug Logging"],
    "Write culler diagnostics to the RPT log each tick.",
    true, {}
] call CBA_fnc_addSetting;

// ── CLIENT RENDERER SETTINGS ───────────────────────────────────────────────
// isGlobal = false: each client sets their own display preferences.

[
    "AIC_showLabels", "CHECKBOX", true,
    ["AI Culler - Client", "Show Unit Name Labels"],
    "Prefix unit names with [Culled] / [Protected] / [Override] when you are Zeus.",
    false, {}
] call CBA_fnc_addSetting;

[
    "AIC_show3DLabels", "CHECKBOX", true,
    ["AI Culler - Client", "Show 3D Floating Labels"],
    "Draw floating 3D text labels above culled/protected/override units in Zeus view.",
    false, {}
] call CBA_fnc_addSetting;

[
    "AIC_labelDist", "SLIDER", [800, 100, 3000, 0],
    ["AI Culler - Client", "3D Label Draw Distance (m)"],
    "Maximum distance from your camera at which 3D labels are rendered.",
    false, {}
] call CBA_fnc_addSetting;
