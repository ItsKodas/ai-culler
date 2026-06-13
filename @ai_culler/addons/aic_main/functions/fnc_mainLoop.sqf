if !(isServer) exitWith {};

diag_log "[AIC] Starting culler loop";

while {true} do {
    private _players = allPlayers select { isPlayer _x };

    // Count protected infantry before the main filter excludes them
    private _protectedCount = {
        alive _x &&
        _x isKindOf "Man" &&
        !isPlayer _x &&
        (_x getVariable ["zeusProtected", false]) &&
        (side _x in [east, resistance, civilian])
    } count allUnits;

    // Managed pool: living AI infantry, unprotected, correct factions
    private _allAI = allUnits select {
        alive _x &&
        _x isKindOf "Man" &&
        !isPlayer _x &&
        !(_x getVariable ["zeusProtected", false]) &&
        (side _x in [east, resistance, civilian])
    };

    private _outOfRange   = [];
    private _inRangeNoLOS = [];
    private _inRangeLOS   = [];

    {
        private _unit     = _x;
        private _cullDist = [_unit] call AIC_fnc_getCullDist;
        private _nearestDist = 99999;
        private _hasLOS      = false;

        {
            private _dist = _x distance _unit;
            if (_dist < _nearestDist) then { _nearestDist = _dist; };
            if (_dist < _cullDist && !_hasLOS) then {
                if ([_x, _unit, 0] call BIS_fnc_checkVisibility > 0.5) then {
                    _hasLOS = true;
                };
            };
        } forEach _players;

        if (_nearestDist > _cullDist) then {
            _outOfRange pushBack [_unit, _nearestDist];
        } else {
            if (_hasLOS) then {
                _inRangeLOS pushBack [_unit, _nearestDist];
            } else {
                _inRangeNoLOS pushBack [_unit, _nearestDist];
            };
        };
    } forEach _allAI;

    _outOfRange   = [_outOfRange,   [], { _x select 1 }, "DESCEND"] call BIS_fnc_sortBy;
    _inRangeNoLOS = [_inRangeNoLOS, [], { _x select 1 }, "DESCEND"] call BIS_fnc_sortBy;

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
