// AIC_fnc_waypointMonitor — polls all AI groups for waypoint count changes.
// Zeus-assigned (or script-assigned) waypoints are detected when count exceeds
// the per-group baseline while not in combat. Runs on the server only.
if (!isServer) exitWith {};

private _aiGroups = { (units _x) findIf { !isPlayer _x && {_x isKindOf "CAManBase"} } != -1 };

// Snapshot editor-placed waypoints per group after mission init
sleep 5;
{
    if (_x getVariable ["AIC_waypointBaseline", -1] < 0) then {
        _x setVariable ["AIC_waypointBaseline", count (waypoints _x)];
    };
} forEach (allGroups select _aiGroups);
if (AIC_debug) then { diag_log "[AIC][WP] Baseline snapshot complete"; };

private _activeGroups = { (units _x) findIf { !isPlayer _x && {alive _x && {_x isKindOf "CAManBase"}} } != -1 };

while {true} do {
    sleep AIC_checkInterval;
    {
        private _grp = _x;

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
        if (!_inCombat && {_cur > _base}) then {
            if (!(_grp getVariable ["AIC_zeusWaypoint", false])) then {
                if (AIC_debug) then { diag_log format ["[AIC][WP] Zeus waypoint detected on group %1 (cur=%2 base=%3)", _grp, _cur, _base]; };
                _grp setVariable ["AIC_zeusWaypoint", true, true];
                private _enabled = [];
                {
                    if (!(_x getVariable ["AIC_zeusProtected", false]) &&
                        {_x getVariable ["AIC_disabled", false]}) then {
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
            if (_cur <= _base || {_curWP >= _cur}) then {
                if (AIC_debug) then { diag_log format ["[AIC][WP] Zeus waypoints cleared on group %1 (cur=%2 base=%3 curWP=%4)", _grp, _cur, _base, _curWP]; };
                _grp setVariable ["AIC_waypointBaseline", _cur];
                _grp setVariable ["AIC_zeusWaypoint", false, true];
                [(units _grp)] remoteExec ["AIC_fnc_updateUnitLabel", 0];
            };
        };
    } forEach (allGroups select _activeGroups);
};
