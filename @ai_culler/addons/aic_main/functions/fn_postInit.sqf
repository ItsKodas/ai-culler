if (isServer) then {
    if (AIC_debug) then { diag_log "[AIC] Server — starting culler loop"; };
    [] spawn AIC_fnc_mainLoop;

    // Set AIC_zeusWaypoint on a group when Zeus dynamically adds a waypoint during the op.
    // Editor-placed waypoints do not trigger this EH, so they won't create false Override state.
    addMissionEventHandler ["WaypointAdded", {
        params ["_grp", "_wpIdx"];
        _grp setVariable ["AIC_zeusWaypoint", true, true];
        {
            if (!isPlayer _x && _x isKindOf "Man" && alive _x &&
                !(_x getVariable ["zeusProtected", false]) &&
                (_x getVariable ["AIC_disabled", false])) then {
                [_x] call AIC_fnc_enableUnit;
            };
        } forEach (units _grp);
    }];

    // Clear the flag once all waypoints for a group are gone (unit finished its task)
    [] spawn {
        while {true} do {
            sleep AIC_checkInterval;
            {
                private _grp = group _x;
                if ((_grp getVariable ["AIC_zeusWaypoint", false]) &&
                    count (waypoints _grp) == 0) then {
                    _grp setVariable ["AIC_zeusWaypoint", false, true];
                    [_x] remoteExec ["AIC_fnc_updateUnitLabel", 0];
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
