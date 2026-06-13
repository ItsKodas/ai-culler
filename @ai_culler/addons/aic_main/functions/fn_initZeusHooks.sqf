if (!hasInterface) exitWith {};

// Status window lifecycle: poll for Zeus display opening and closing
[] spawn {
    while {true} do {
        waitUntil { !isNull (findDisplay 312) };
        [findDisplay 312] call AIC_fnc_createStatusWindow;

        // Refresh unit labels for units already in a culled or protected state
        { if (alive _x && _x isKindOf "Man" && !isPlayer _x) then { [_x] call AIC_fnc_updateUnitLabel; }; } forEach allUnits;

        waitUntil { isNull (findDisplay 312) };
    };
};

// ZEN context menu integration — registers once per session if ZEN is present
if (!isNil "zen_context_menu_fnc_createAction") then {
    private _action = [
        "AIC_ToggleProtection",
        "Toggle Culler Protection",
        "",
        { [_objects] remoteExec ["AIC_fnc_toggleProtection", 2]; },
        { _objects findIf { alive _x && !isPlayer _x && _x isKindOf "Man" } != -1 }
    ] call zen_context_menu_fnc_createAction;
    [_action] call zen_context_menu_fnc_addAction;
    if (AIC_debug) then { diag_log "[AIC] ZEN context menu: Toggle Culler Protection registered"; };
};
