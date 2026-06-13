if (!hasInterface) exitWith {};

// Status window lifecycle: poll for Zeus display opening and closing
[] spawn {
    private _drawEH = -1;
    while {true} do {
        waitUntil { !isNull (findDisplay 312) };
        [findDisplay 312] call AIC_fnc_createStatusWindow;

        // Broadcast camera position to server every 3 s so the culler treats Zeus view as a proximity anchor
        [] spawn {
            while { !isNull (findDisplay 312) } do {
                player setVariable ["AIC_zeusPos", positionCameraToWorld [0,0,0], true];
                sleep 3;
            };
            player setVariable ["AIC_zeusPos", nil, true];
        };

        // Refresh name prefixes for units already flagged
        { if (alive _x && _x isKindOf "Man" && !isPlayer _x) then { [_x] call AIC_fnc_updateUnitLabel; }; } forEach allUnits;

        // Draw floating 3D labels above protected/culled/overridden units — visible only to this Zeus client
        _drawEH = addMissionEventHandler ["Draw3D", {
            private _camPos = positionCameraToWorld [0,0,0];
            {
                private _prot = _x getVariable ["zeusProtected", false];
                private _cull = _x getVariable ["AIC_disabled",  false];
                private _over = !_cull && !_prot && count (waypoints (group _x)) > 0;
                if (_prot || _cull || _over) then {
                    if (_camPos distance _x < 800) then {
                        private _color = [1.0, 0.55, 0.0, 1.0];
                        private _label = "[Culled]";
                        if (_over) then { _color = [0.0, 0.7, 1.0, 1.0]; _label = "[Override]"; };
                        if (_prot) then { _color = [0.2, 1.0, 0.2, 1.0]; _label = "[Protected]"; };
                        drawIcon3D ["", _color, (ASLToAGL getPosASLVisual _x) vectorAdd [0, 0, 2.5], 0, 0, 0, _label, 2, 0.035, "RobotoCondensed"];
                    };
                };
            } forEach allUnits;
        }];

        waitUntil { isNull (findDisplay 312) };

        removeMissionEventHandler ["Draw3D", _drawEH];
        _drawEH = -1;
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
