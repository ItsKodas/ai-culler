if (isServer) then {
    if (AIC_debug) then { diag_log "[AIC] Server — starting culler loop"; };
    [] spawn AIC_fnc_mainLoop;

    // Detect Zeus-assigned waypoints by comparing live count against a per-group baseline.
    // addMissionEventHandler ["WaypointAdded"] is not valid in Arma 3; polling is the only option.
    // Editor-placed waypoints are captured in the baseline, so they never trigger Override.
    [] spawn {
        // Snapshot editor-placed waypoints per group after mission init
        sleep 5;
        {
            private _grp = group _x;
            if (_grp getVariable ["AIC_waypointBaseline", -1] < 0) then {
                _grp setVariable ["AIC_waypointBaseline", count (waypoints _grp)];
            };
        } forEach (allUnits select { !isPlayer _x && _x isKindOf "Man" });

        while {true} do {
            sleep AIC_checkInterval;
            private _seen = [];
            {
                private _grp = group _x;
                if !(_grp in _seen) then {
                    _seen pushBack _grp;

                    // Groups that spawned mid-mission haven't been baselined yet; treat as 0
                    if (_grp getVariable ["AIC_waypointBaseline", -1] < 0) then {
                        _grp setVariable ["AIC_waypointBaseline", 0];
                    };

                    private _base = _grp getVariable "AIC_waypointBaseline";
                    private _cur  = count (waypoints _grp);

                    if (_cur > _base) then {
                        if (!(_grp getVariable ["AIC_zeusWaypoint", false])) then {
                            _grp setVariable ["AIC_zeusWaypoint", true, true];
                            {
                                if (!(_x getVariable ["zeusProtected", false]) &&
                                    (_x getVariable ["AIC_disabled", false])) then {
                                    [_x] call AIC_fnc_enableUnit;
                                };
                            } forEach (units _grp);
                        };
                    } else {
                        if (_grp getVariable ["AIC_zeusWaypoint", false]) then {
                            _grp setVariable ["AIC_zeusWaypoint", false, true];
                            { [_x] remoteExec ["AIC_fnc_updateUnitLabel", 0]; } forEach (units _grp);
                        };
                    };
                };
            } forEach (allUnits select { !isPlayer _x && _x isKindOf "Man" && alive _x });
        };
    };
};

if (hasInterface) then {
    [] spawn {
        waitUntil { !isNull player };
        if (AIC_debug) then { diag_log "[AIC] Interface machine — init Zeus hooks"; };
        [] call AIC_fnc_initZeusHooks;
    };
};
