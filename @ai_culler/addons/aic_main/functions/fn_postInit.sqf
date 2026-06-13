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
        if (AIC_debug) then { diag_log "[AIC][WP] Baseline snapshot complete"; };

        while {true} do {
            sleep AIC_checkInterval;
            private _seen = [];
            {
                private _grp = group _x;
                if !(_grp in _seen) then {
                    _seen pushBack _grp;

                    // Groups that spawned mid-mission haven't been baselined yet; snapshot current count
                    if (_grp getVariable ["AIC_waypointBaseline", -1] < 0) then {
                        _grp setVariable ["AIC_waypointBaseline", count (waypoints _grp)];
                    };

                    private _base = _grp getVariable "AIC_waypointBaseline";
                    private _cur  = count (waypoints _grp);
                    // Ignore waypoint changes while group is in combat — Arma generates its own
                    // combat waypoints (SAD etc.) that are indistinguishable from Zeus-placed ones
                    private _inCombat = (units _grp) findIf { behaviour _x == "COMBAT" } != -1;

                    // Only set override when not in combat (combat waypoints are system-generated)
                    if (!_inCombat && _cur > _base) then {
                        if (!(_grp getVariable ["AIC_zeusWaypoint", false])) then {
                            if (AIC_debug) then { diag_log format ["[AIC][WP] Zeus waypoint detected on group %1 (cur=%2 base=%3)", _grp, _cur, _base]; };
                            _grp setVariable ["AIC_zeusWaypoint", true, true];
                            {
                                if (!(_x getVariable ["zeusProtected", false]) &&
                                    (_x getVariable ["AIC_disabled", false])) then {
                                    [_x] call AIC_fnc_enableUnit;
                                };
                            } forEach (units _grp);
                        };
                    };
                    // Clear override when:
                    // a) waypoints were manually deleted (cur dropped back to base)
                    // b) AI completed all Zeus waypoints — Arma doesn't remove completed waypoints
                    //    from the array, so we use currentWaypoint to detect when AI has moved
                    //    past the Zeus-added range. Baseline is updated so completed waypoints
                    //    don't re-trigger on future polls.
                    if (_grp getVariable ["AIC_zeusWaypoint", false]) then {
                        private _curWP = currentWaypoint _grp;
                        if (_cur <= _base || _curWP >= _cur) then {
                            if (AIC_debug) then { diag_log format ["[AIC][WP] Zeus waypoints cleared on group %1 (cur=%2 base=%3 curWP=%4)", _grp, _cur, _base, _curWP]; };
                            _grp setVariable ["AIC_waypointBaseline", _cur];
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
