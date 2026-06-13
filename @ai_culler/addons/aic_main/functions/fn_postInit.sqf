if (isServer) then {
    if (AIC_debug) then { diag_log "[AIC] Server — starting culler loop"; };
    [] spawn AIC_fnc_mainLoop;

    // Re-enable culled units immediately when Zeus assigns them a waypoint.
    // Polls every 1 s — faster than the main culler cycle — so units move without delay.
    [] spawn {
        while {true} do {
            sleep 1;
            if (!AIC_cullerEnabled) then { continue };
            {
                if (!isPlayer _x && _x isKindOf "Man" && alive _x &&
                    !(_x getVariable ["zeusProtected", false]) &&
                    (_x getVariable ["AIC_disabled", false]) &&
                    count (waypoints (group _x)) > 0) then {
                    [_x] call AIC_fnc_enableUnit;
                };
            } forEach allUnits;
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
