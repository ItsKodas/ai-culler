// AIC_fnc_waypointMonitor — polls all AI groups for outstanding waypoints.
// A group is forced active when currentWaypoint != count (waypoints), meaning
// it has waypoints it has not yet reached.  Clears automatically once the
// group reaches or passes the last waypoint.  Runs on the server only.
if (!isServer) exitWith {};

while { true } do {
	sleep AIC_checkInterval;
	{
		private _grp = _x;
		private _wpCount = count (waypoints _grp);
		private _curWP = currentWaypoint _grp;

		if (_wpCount > _curWP) then {
			if (!(_grp getVariable ["AIC_zeusWaypoint", false])) then {
				if (AIC_debug) then {
					diag_log format ["[AIC][WP] Active waypoints on group %1 (count=%2 cur=%3)", _grp, _wpCount, _curWP];
				};
				_grp setVariable ["AIC_zeusWaypoint", true, true];
				private _enabled = (units _grp) select {
					!(_x getVariable ["AIC_zeusProtected", false]) &&
					{_x getVariable ["AIC_disabled", false]}
				};
				if (_enabled isNotEqualTo []) then {
					[_enabled, true] call AIC_fnc_setSimulation;
					[_enabled] remoteExec ["AIC_fnc_updateUnitLabel", 0];
				};
			};
		} else {
			if (_grp getVariable ["AIC_zeusWaypoint", false]) then {
				if (AIC_debug) then {
					diag_log format ["[AIC][WP] Waypoints cleared on group %1 (count=%2 cur=%3)", _grp, _wpCount, _curWP];
				};
				_grp setVariable ["AIC_zeusWaypoint", false, true];
				[(units _grp)] remoteExec ["AIC_fnc_updateUnitLabel", 0];
			};
		};
	} forEach allGroups;
};