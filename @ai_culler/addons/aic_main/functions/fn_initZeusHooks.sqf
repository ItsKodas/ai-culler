if (!hasInterface) exitWith {};

// Status window lifecycle: poll for Zeus display opening and closing
[] spawn {
    private _drawEH = -1;
    while {true} do {
        waitUntil { !isNull (findDisplay 312) };
        [findDisplay 312] call AIC_fnc_createStatusWindow;
        [findDisplay 312] call AIC_fnc_createFpsGraphPanel;

        // Mirror Backspace HUD toggle: hide/show AIC panel when Zeus hides/shows its own HUD
        // DIK 14 = Backspace. Returning false lets Zeus still toggle its own controls.
        (findDisplay 312) displayAddEventHandler ["KeyDown", {
            params ["_disp", "_key"];
            if (_key == 14) then {
                private _bg = _disp displayCtrl 9200;
                if (!isNull _bg) then {
                    if (!(_bg getVariable ["AIC_hidden", false])) then {
                        _bg setVariable ["AIC_hidden", true];
                        { private _c = _disp displayCtrl _x; if (!isNull _c) then { _c ctrlShow false; _c ctrlCommit 0; }; }
                            forEach [9200,9201,9202,9203,9204,9205,9206,9207,9221,9229,9230,9231,9208,9209,9250,9210,9211,9212,9213,9214,9215,9216,9217,9218,9219,9222,9223,9224,9225,9227,9228,9226,9220,9251,9252,9253,9254];
                    } else {
                        _bg setVariable ["AIC_hidden", false];
                        private _collapsed    = (_disp displayCtrl 9202) getVariable ["AIC_collapsed", false];
                        private _settingsOpen = (_disp displayCtrl 9209) getVariable ["AIC_settingsOpen", false];
                        private _graphOpen    = (_disp displayCtrl 9250) getVariable ["AIC_graphOpen", false];
                        { private _c = _disp displayCtrl _x; if (!isNull _c) then { _c ctrlShow true; _c ctrlCommit 0; }; }
                            forEach [9200,9201,9202];
                        if (!_collapsed) then {
                            { private _c = _disp displayCtrl _x; if (!isNull _c) then { _c ctrlShow true; _c ctrlCommit 0; }; }
                                forEach [9203,9204,9205,9206,9207,9221,9229,9230,9231,9208,9209,9250];
                            if (_graphOpen) then {
                                { private _c = _disp displayCtrl _x; if (!isNull _c) then { _c ctrlShow true; _c ctrlCommit 0; }; }
                                    forEach [9251,9252,9253,9254];
                            };
                            if (_settingsOpen) then {
                                { private _c = _disp displayCtrl _x; if (!isNull _c) then { _c ctrlShow true; _c ctrlCommit 0; }; }
                                    forEach [9210,9211,9212,9213,9214,9215,9216,9217,9218,9219,9222,9223,9224,9225,9227,9228,9226,9220];
                            };
                        };
                    };
                };
            };
            false
        }];

        // 1-second FPS refresh - updates Srv/Clt FPS rows and feeds the FPS graph.
        // History array length == graph column count; oldest entry is dropped from
        // the front each tick once full, so the array IS the display data directly.
        if (isNil "AIC_fpsHistory") then { AIC_fpsHistory = [] };
        [] spawn {
            while { !isNull (findDisplay 312) } do {
                sleep 1;
                private _disp = findDisplay 312;
                if (!isNull _disp) then {
                    private _srvCtrl = _disp displayCtrl 9230;
                    private _cltCtrl = _disp displayCtrl 9231;
                    if (!isNull _srvCtrl) then {
                        _srvCtrl ctrlSetText format ["Srv FPS: %1", if (!isNil "AIC_serverFPS") then { AIC_serverFPS } else { "..." }];
                        _srvCtrl ctrlCommit 0;
                    };
                    if (!isNull _cltCtrl) then { _cltCtrl ctrlSetText format ["Clt FPS: %1", round diag_fps]; _cltCtrl ctrlCommit 0; };

                    if (!isNil "AIC_serverFPS") then {
                        if (isNil "AIC_fpsHistory") then { AIC_fpsHistory = [] };
                        if (count AIC_fpsHistory >= 88) then { AIC_fpsHistory deleteAt 0 };
                        AIC_fpsHistory pushBack AIC_serverFPS;
                        [] call AIC_fnc_renderFpsGraph;
                    };
                };
            };
        };

        // Batch-refresh name prefixes for all currently flagged units
        private _labelled = allUnits select { alive _x && _x isKindOf "CAManBase" && vehicle _x == _x && !isPlayer _x };
        if (_labelled isNotEqualTo []) then { [_labelled] call AIC_fnc_updateUnitLabel };

        // Draw floating 3D labels above protected/culled/overridden units — visible only to this Zeus client
        _drawEH = addMissionEventHandler ["Draw3D", {
            if (!AIC_show3DLabels) exitWith {};
            private _camPos = positionCameraToWorld [0,0,0];
            {
                private _prot = _x getVariable ["AIC_zeusProtected", false];
                private _cull = _x getVariable ["AIC_disabled",  false];
                private _over = !_cull && !_prot && (group _x) getVariable ["AIC_zeusWaypoint", false];
                if (_prot || _cull || _over) then {
                    if (_camPos distance _x < AIC_labelDist) then {
                        private _color = [1.0, 0.55, 0.0, 1.0];
                        private _label = "[Culled]";
                        if (_over) then { _color = [0.0, 0.7, 1.0, 1.0]; _label = "[Override]"; };
                        if (_prot) then { _color = [0.2, 1.0, 0.2, 1.0]; _label = "[Protected]"; };
                        drawIcon3D ["", _color, (ASLToAGL getPosASLVisual _x) vectorAdd [0, 0, 2.5], 0, 0, 0, _label, 2, 0.035, "RobotoCondensed"];
                    };
                };
            } forEach (allUnits select { !isPlayer _x && { _x isKindOf "CAManBase" && { vehicle _x == _x } } });
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
        { _objects findIf { alive _x && !isPlayer _x && _x isKindOf "CAManBase" } != -1 }
    ] call zen_context_menu_fnc_createAction;
    [_action] call zen_context_menu_fnc_addAction;
    if (AIC_debug) then { diag_log "[AIC] ZEN context menu: Toggle Culler Protection registered"; };
};
