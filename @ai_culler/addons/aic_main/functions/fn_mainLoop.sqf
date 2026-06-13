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

    // Reference points: player eye positions only. Each entry: [eyePosASL, playerObj]
    private _refPoints = _players apply { [eyePos _x, _x] };

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

    private _outOfRange   = [];
    private _inRangeNoLOS = [];
    private _inRangeLOS   = [];

    {
        private _unit     = _x;
        private _cullDist = [_unit] call AIC_fnc_getCullDist;

        // Pass 1: find nearest reference point (player body or Zeus camera)
        private _nearestDist   = 99999;
        private _nearestEyePos = [0,0,0];
        private _nearestPlayer = objNull;
        {
            private _d = _unit distance (_x select 0);
            if (_d < _nearestDist) then {
                _nearestDist   = _d;
                _nearestEyePos = _x select 0;
                _nearestPlayer = _x select 1;
            };
        } forEach _refPoints;

        if (_nearestDist > _cullDist) then {
            // Out of range — cull
            _outOfRange pushBack [_unit, _nearestDist];
        } else {
            if (_nearestDist <= AIC_minActiveRadius || (group _unit) getVariable ["AIC_zeusWaypoint", false]) then {
                // Proximity override (200 m) or Zeus-assigned waypoint — always active, skip raycast
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
                    // LOS check against nearest player body
                    // terrainIntersectASL catches hills; lineIntersectsObjs catches buildings
                    private _hasLOS = !(terrainIntersectASL [_nearestEyePos, eyePos _unit]);
                    if (_hasLOS) then {
                        private _hits = lineIntersectsObjs [_nearestEyePos, eyePos _unit, _nearestPlayer, _unit];
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

    private _culledCount    = (count _allAI) - _activeCount;
    private _overrideCount  = { (group _x) getVariable ["AIC_zeusWaypoint", false] } count _allAI;

    if (AIC_debug) then {
        diag_log format [
            "[AIC] Active: %1 / %2 | LOS: %3 | No-LOS: %4 | Out: %5 | Protected: %6 | Culled: %7 | Override: %8",
            _activeCount, AIC_maxActiveAI,
            count _inRangeLOS, count _inRangeNoLOS,
            count _outOfRange, _protectedCount, _culledCount, _overrideCount
        ];
    };

    [_activeCount, count _inRangeLOS, count _inRangeNoLOS, count _outOfRange, _protectedCount, _culledCount, _overrideCount]
        call AIC_fnc_broadcastStats;

    sleep AIC_checkInterval;
};
