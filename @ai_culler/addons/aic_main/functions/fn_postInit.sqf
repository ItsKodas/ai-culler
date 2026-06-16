// Register CBA settings after CBA XEH PreInit has finished so they survive
// CBA's internal registry reset at the start of its XEH phase.
diag_log "[AIC] postInit: registering settings";
[] call AIC_fnc_registerSettings;
diag_log "[AIC] postInit: settings registered";

if (isServer) then {
    if (AIC_debug) then { diag_log "[AIC] Server — starting culler loop"; };
    [] spawn AIC_fnc_mainLoop;

    // Seed with current FPS before mission load so the initial display is close
    // to the server's configured cap rather than an arbitrary placeholder.
    AIC_serverFPS = round diag_fps;

    // Keep updating every second, independent of the culler tick, so the
    // reading is not biased by the culler's own processing load.
    // Send only to active curator clients rather than broadcasting to everyone.
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
        } forEach (allUnits select { !isPlayer _x && _x isKindOf "CAManBase" });
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
                            [(units _grp)] remoteExec ["AIC_fnc_updateUnitLabel", 0];
                        };
                    };
                };
            } forEach (allUnits select { !isPlayer _x && _x isKindOf "CAManBase" && alive _x });
        };
    };
};

// postInit: player is already initialised on interface machines — no spawn or waitUntil needed
if (hasInterface) then {
    if (AIC_debug) then { diag_log "[AIC] Interface machine — init Zeus hooks"; };
    [] call AIC_fnc_initZeusHooks;
};
