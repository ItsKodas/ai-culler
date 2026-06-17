// AIC_fnc_registerSettings — registers all CBA Addon Options settings.
// Called from fn_preInit. Exits silently if CBA_A3 is not loaded.
// Parameter order: [name, type, [title, tooltip], category, valueInfo, isGlobal, script]
diag_log "[AIC] fn_registerSettings: running";
diag_log format ["[AIC] CBA_fnc_addSetting is nil: %1", isNil "CBA_fnc_addSetting"];
if (isNil "CBA_fnc_addSetting") exitWith { diag_log "[AIC] fn_registerSettings: CBA not found, exiting" };

// ── SERVER SETTINGS (isGlobal = 1: server value broadcast to all clients) ──

[
    "AIC_cullerEnabled",
    "CHECKBOX",
    ["Enable Culler on Start", "Start the mission with the AI culling system active."],
    "AI Culler",
    true,
    1,
    {}
] call CBA_fnc_addSetting;

[
    "AIC_maxActiveAI",
    "SLIDER",
    ["Max Active AI", "Maximum number of AI units the culler allows to be active simultaneously."],
    "AI Culler",
    [10, 500, 150, 0],
    1,
    {}
] call CBA_fnc_addSetting;

[
    "AIC_distBlufor",
    "SLIDER",
    ["BLUFOR Cull Distance (m)", "Distance beyond which BLUFOR AI infantry are culled."],
    "AI Culler",
    [100, 8000, 2000, 0],
    1,
    {}
] call CBA_fnc_addSetting;

[
    "AIC_distOpfor",
    "SLIDER",
    ["OPFOR Cull Distance (m)", "Distance beyond which OPFOR AI infantry are culled."],
    "AI Culler",
    [100, 8000, 2000, 0],
    1,
    {}
] call CBA_fnc_addSetting;

[
    "AIC_distIndependent",
    "SLIDER",
    ["Independent Cull Distance (m)", "Distance beyond which Independent AI infantry are culled."],
    "AI Culler",
    [100, 8000, 2000, 0],
    1,
    {}
] call CBA_fnc_addSetting;

[
    "AIC_distCivilian",
    "SLIDER",
    ["Civilian Cull Distance (m)", "Distance beyond which Civilian AI are culled. Set to 0 to always cull."],
    "AI Culler",
    [0, 3000, 500, 0],
    1,
    {}
] call CBA_fnc_addSetting;

[
    "AIC_checkInterval",
    "SLIDER",
    ["Check Interval (s)", "How often the culler re-evaluates all AI units."],
    "AI Culler",
    [1, 30, 5, 0],
    1,
    {}
] call CBA_fnc_addSetting;

[
    "AIC_minActiveRadius",
    "SLIDER",
    ["Min Active Radius (m)", "AI within this distance of any player are always active, skipping the LOS check."],
    "AI Culler",
    [25, 1000, 200, 0],
    1,
    {}
] call CBA_fnc_addSetting;

[
    "AIC_combatRadius",
    "SLIDER",
    ["Combat Detection Radius (m)", "Radius used to detect active combat between AI units."],
    "AI Culler",
    [50, 1500, 400, 0],
    1,
    {}
] call CBA_fnc_addSetting;

[
    "AIC_debug",
    "CHECKBOX",
    ["Debug Logging", "Write culler diagnostics to the RPT log each tick."],
    "AI Culler",
    false,
    1,
    {}
] call CBA_fnc_addSetting;

[
    "AIC_showNotifications",
    "CHECKBOX",
    ["Show Enable/Disable Notifications", "Show a notification to all players when the culler is enabled or disabled."],
    "AI Culler",
    true,
    1,
    {}
] call CBA_fnc_addSetting;

// ── CLIENT SETTINGS (isGlobal = 0: per-client display preferences) ──────────

[
    "AIC_clientEnabled",
    "CHECKBOX",
    ["Enable Client Renderer", "Hide AI units that are behind terrain from your view. Reduces GPU load."],
    "AI Culler - Client",
    true,
    0,
    { [_this] call AIC_fnc_clientLoop }
] call CBA_fnc_addSetting;

[
    "AIC_showLabels",
    "CHECKBOX",
    ["Show Unit Name Labels", "Prefix unit names with [Culled] / [Protected] / [Override] when you are Zeus."],
    "AI Culler - Client",
    true,
    0,
    {}
] call CBA_fnc_addSetting;

[
    "AIC_show3DLabels",
    "CHECKBOX",
    ["Show 3D Floating Labels", "Draw floating 3D labels above culled/protected/override units in Zeus view."],
    "AI Culler - Client",
    true,
    0,
    {}
] call CBA_fnc_addSetting;

[
    "AIC_labelDist",
    "SLIDER",
    ["3D Label Draw Distance (m)", "Maximum distance from your Zeus camera at which 3D labels are rendered."],
    "AI Culler - Client",
    [100, 3000, 800, 0],
    0,
    {}
] call CBA_fnc_addSetting;

[
    "AIC_clientSafeRadius",
    "SLIDER",
    ["Safe Radius (m)", "AI within this distance are always visible regardless of line of sight."],
    "AI Culler - Client",
    [0, 500, 150, 0],
    0,
    {}
] call CBA_fnc_addSetting;

[
    "AIC_clientSurfaceRadius",
    "SLIDER",
    ["Surface LOS Radius (m)", "Within this distance, full surface intersection (buildings, walls) is used instead of terrain-only LOS."],
    "AI Culler - Client",
    [0, 1500, 600, 0],
    0,
    {}
] call CBA_fnc_addSetting;

[
    "AIC_clientDebug",
    "CHECKBOX",
    ["Debug HUD", "Show the client renderer debug overlay on all clients."],
    "AI Culler - Client",
    false,
    1,
    {}
] call CBA_fnc_addSetting;
