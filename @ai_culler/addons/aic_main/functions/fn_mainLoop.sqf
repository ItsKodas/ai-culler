if !(isServer) exitWith {};

diag_log "[AIC] Starting culler loop";

while {true} do {
    if (!AIC_cullerEnabled) then {
        // Re-enable any units that were disabled before culler was turned off
        { [_x] call AIC_fnc_enableUnit; } forEach (allUnits select { _x getVariable ["AIC_disabled", false] });
        sleep AIC_checkInterval;
        continue;
    };

    private _players = allPlayers select { isPlayer _x };

    // Count protected infantry before the main filter excludes them
    private _protectedCount = {
        alive _x &&
        _x isKindOf "Man" &&
        !isPlayer _x &&
        (_x getVariable ["zeusProtected", false]) &&
        (side _x in [west, east, resistance, civilian])
    } count allUnits;

    // Managed pool: living AI infantry, unprotected, all factions
    private _allAI = allUnits select {
        alive _x &&
        _x isKindOf "Man" &&
        !isPlayer _x &&
        !(_x getVariable ["zeusProtected", false]) &&
        (side _x in [west, east, resistance, civilian])
    };

    // Register WaypointAdded EH on any new managed group — fires server-side for both
    // Zeus group waypoints and single-unit waypoints (both target the group in Arma 3)
    {
        private _grp = group _x;
        if !(_grp in AIC_waypointEHGroups) then {
            _grp addEventHandler ["WaypointAdded", {
                params ["_grp"];
                {
                    if (!(_x getVariable ["zeusProtected", false])) then {
                        [_x] call AIC_fnc_enableUnit;
                    };
                    [_x] remoteExec ["AIC_fnc_updateUnitLabel", 0];
                } forEach (units _grp);
            }];
            AIC_waypointEHGroups pushBack _grp;
        };
    } forEach _allAI;

    private _outOfRange   = [];
    private _inRangeNoLOS = [];
    private _inRangeLOS   = [];

    {
        private _unit     = _x;
        private _cullDist = [_unit] call AIC_fnc_getCullDist;

        // Pass 1: find nearest player with cheap distance math only
        private _nearestDist   = 99999;
        private _nearestPlayer = objNull;
        {
            private _d = _unit distance _x;
            if (_d < _nearestDist) then {
                _nearestDist   = _d;
                _nearestPlayer = _x;
            };
        } forEach _players;

        if (_nearestDist > _cullDist) then {
            // Out of range — cull
            _outOfRange pushBack [_unit, _nearestDist];
        } else {
            if (_nearestDist <= AIC_minActiveRadius || count (waypoints (group _unit)) > 0) then {
                // Proximity override (200 m) or group has active waypoints — always active, skip raycast
                _inRangeLOS pushBack [_unit, _nearestDist];
            } else {
                // Combat check: if hostile non-civilian AI are nearby, keep active so AI vs AI fights resolve
                // Civilians are excluded — they don't trigger combat activation
                private _inCombat = side _unit != civilian && {
                    _unit nearEntities [["Man"], AIC_combatRadius] findIf {
                        alive _x && !isPlayer _x && side _x != civilian &&
                        (side _x getFriend side _unit) < 0.6
                    } != -1
                };

                if (_inCombat) then {
                    _inRangeLOS pushBack [_unit, _nearestDist];
                } else {
                    // LOS check against nearest player only (not all players)
                    // terrainIntersectASL catches hills; lineIntersectsObjs catches buildings
                    // lineIntersectsObjs ignores terrain trees naturally (they are terrain geometry, not objects)
                    private _hasLOS = !(terrainIntersectASL [eyePos _nearestPlayer, eyePos _unit]);
                    if (_hasLOS) then {
                        private _hits = lineIntersectsObjs [eyePos _nearestPlayer, eyePos _unit, _nearestPlayer, _unit];
                        _hasLOS = (_hits findIf { !(_x isKindOf "Tree") && !(_x isKindOf "Bush") }) == -1;
                    };

                    if (_hasLOS) then {
                        _inRangeLOS pushBack [_unit, _nearestDist];
                    } else {
                        _inRangeNoLOS pushBack [_unit, _nearestDist];
                    };
                };
            };
        };
    } forEach _allAI;

    _outOfRange   = [_outOfRange,   [], { _x select 1 }, "DESCEND"] call BIS_fnc_sortBy;
    _inRangeNoLOS = [_inRangeNoLOS, [], { _x select 1 }, "ASCEND"] call BIS_fnc_sortBy;

    { [_x select 0] call AIC_fnc_disableUnit; } forEach _outOfRange;

    private _activeCount = 0;
    {
        [_x select 0] call AIC_fnc_enableUnit;
        _activeCount = _activeCount + 1;
    } forEach _inRangeLOS;

    {
        private _unit = _x select 0;
        if (_activeCount < AIC_maxActiveAI) then {
            [_unit] call AIC_fnc_enableUnit;
            _activeCount = _activeCount + 1;
        } else {
            [_unit] call AIC_fnc_disableUnit;
        };
    } forEach _inRangeNoLOS;

    private _culledCount = (count _allAI) - _activeCount;

    if (AIC_debug) then {
        diag_log format [
            "[AIC] Active: %1 / %2 | LOS: %3 | No-LOS: %4 | Out of range: %5 | Protected: %6 | Culled: %7",
            _activeCount, AIC_maxActiveAI,
            count _inRangeLOS, count _inRangeNoLOS,
            count _outOfRange, _protectedCount, _culledCount
        ];
    };

    [_activeCount, count _inRangeLOS, count _inRangeNoLOS, count _outOfRange, _protectedCount, _culledCount]
        call AIC_fnc_broadcastStats;

    sleep AIC_checkInterval;
};
