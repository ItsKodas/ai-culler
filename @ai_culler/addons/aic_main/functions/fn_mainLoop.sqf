if !(isServer) exitWith {};

diag_log "[AIC] Starting culler loop";

while {true} do {
    private _allUnitsRaw = allUnits;

    if (!AIC_cullerEnabled) then {
        // Re-enable any units that were disabled before culler was turned off
        private _toEnable = _allUnitsRaw select { _x getVariable ["AIC_disabled", false] };
        { [_x] call AIC_fnc_enableUnit; } forEach _toEnable;
        if (_toEnable isNotEqualTo []) then {
            [_toEnable] remoteExec ["AIC_fnc_updateUnitLabel", 0];
        };
        private _totalAI = { alive _x && _x isKindOf "CAManBase" && !isPlayer _x } count _allUnitsRaw;
        [0, 0, 0, 0, 0, 0, 0, _totalAI, AIC_serverFPS] call AIC_fnc_broadcastStats;
        sleep AIC_checkInterval;
        continue;
    };

    private _players = allPlayers select { isPlayer _x };

    // Reference points: player eye positions only. Each entry: [eyePosASL, playerObj]
    private _refPoints = _players apply { [eyePos _x, _x] };

    // Count protected infantry before the main filter excludes them
    private _protectedCount = {
        alive _x &&
        _x isKindOf "CAManBase" &&
        vehicle _x == _x &&
        !isPlayer _x &&
        (_x getVariable ["AIC_zeusProtected", false]) &&
        (side _x in [west, east, resistance, civilian])
    } count _allUnitsRaw;

    // Managed pool: living AI infantry on foot, unprotected, all factions.
    // vehicle _x == _x excludes crew seated inside vehicles — culling crew breaks the vehicle.
    private _allAI = _allUnitsRaw select {
        alive _x &&
        _x isKindOf "CAManBase" &&
        vehicle _x == _x &&
        !isPlayer _x &&
        !(_x getVariable ["AIC_zeusProtected", false]) &&
        (side _x in [west, east, resistance, civilian])
    };

    private _outOfRange   = [];
    private _inRangeNoLOS = [];
    private _inRangeLOS   = [];
    private _labelUpdates = [];

    // Process in chunks of 25, yielding between chunks to spread raycasts and
    // nearEntities calls across time rather than blocking the server thread.
    // Target: consume ~40% of the check interval (2s at default 5s).
    // Yield time shrinks as AI count grows so total spread stays consistent.
    private _chunkSize  = 25;
    private _numChunks  = (ceil ((count _allAI) / _chunkSize)) max 1;
    private _yieldTime  = (AIC_checkInterval * 0.4) / _numChunks;
    private _chunkCount = 0;
    {
        private _unit = _x;
        // Unit may have died or been protected during a yield between chunks
        if (!alive _unit || { _unit getVariable ["AIC_zeusProtected", false] }) then { continue };

        private _cullDist = [_unit] call AIC_fnc_getCullDist;

        // Find nearest reference point distance (for range check)
        private _nearestDist = 99999;
        {
            private _d = _unit distance (_x select 0);
            if (_d < _nearestDist) then { _nearestDist = _d };
        } forEach _refPoints;

        private _inCombat = side _unit != civilian && {
            _unit nearEntities [["CAManBase"], AIC_combatRadius] findIf {
                alive _x && !isPlayer _x && side _x != civilian &&
                (side _x getFriend side _unit) < 0.6
            } != -1
        };

        if ((group _unit) getVariable ["AIC_zeusWaypoint", false] || _inCombat) then {
            // Zeus-assigned waypoint or AI vs AI combat — active regardless of player proximity
            _inRangeLOS pushBack _unit;
        } else {
            if (_nearestDist > _cullDist) then {
                // Out of range — cull
                _outOfRange pushBack _unit;
            } else {
                if ((_refPoints findIf { _unit distance (_x select 0) <= AIC_minActiveRadius }) != -1) then {
                    // Within minimum active radius of any player — always active, skip raycast
                    _inRangeLOS pushBack _unit;
                } else {
                    // LOS check against ALL players — active if any has line of sight
                    // terrainIntersectASL catches hills; lineIntersectsObjs catches buildings
                    private _unitEyePos = eyePos _unit;
                    private _hasLOS = (_refPoints findIf {
                        private _eyePos = _x select 0;
                        private _player = _x select 1;
                        private _los = !(terrainIntersectASL [_eyePos, _unitEyePos]);
                        if (_los) then {
                            private _hits = lineIntersectsObjs [_eyePos, _unitEyePos, _player, _unit];
                            _los = (_hits findIf { !(_x isKindOf "Tree") && !(_x isKindOf "Bush") }) == -1;
                        };
                        _los
                    }) != -1;

                    if (_hasLOS) then {
                        _inRangeLOS pushBack _unit;
                    } else {
                        _inRangeNoLOS pushBack [_unit, _nearestDist];
                    };
                };
            };
        };

        _chunkCount = _chunkCount + 1;
        if ((_chunkCount % _chunkSize) == 0 && _chunkCount < count _allAI) then { sleep _yieldTime; };
    } forEach _allAI;

    {
        if (!(_x getVariable ["AIC_disabled", false])) then { _labelUpdates pushBack _x };
        [_x] call AIC_fnc_disableUnit;
    } forEach _outOfRange;

    private _activeCount = 0;
    {
        if (_x getVariable ["AIC_disabled", false]) then { _labelUpdates pushBack _x };
        [_x] call AIC_fnc_enableUnit;
        _activeCount = _activeCount + 1;
    } forEach _inRangeLOS;

    // Sort ascending by distance so the closest no-LOS units fill the cap first
    _inRangeNoLOS = [_inRangeNoLOS, [], { _x select 1 }, "ASCEND"] call BIS_fnc_sortBy;
    {
        private _unit = _x select 0;
        if (_activeCount < AIC_maxActiveAI) then {
            if (_unit getVariable ["AIC_disabled", false]) then { _labelUpdates pushBack _unit };
            [_unit] call AIC_fnc_enableUnit;
            _activeCount = _activeCount + 1;
        } else {
            if (!(_unit getVariable ["AIC_disabled", false])) then { _labelUpdates pushBack _unit };
            [_unit] call AIC_fnc_disableUnit;
        };
    } forEach _inRangeNoLOS;

    if (_labelUpdates isNotEqualTo []) then {
        [_labelUpdates] remoteExec ["AIC_fnc_updateUnitLabel", 0];
    };

    private _culledCount   = (count _allAI) - _activeCount;
    private _overrideCount = { (group _x) getVariable ["AIC_zeusWaypoint", false] } count _allAI;
    private _totalAI       = (count _allAI) + _protectedCount;

    if (AIC_debug) then {
        diag_log format [
            "[AIC] Active: %1 / %2 | LOS: %3 | No-LOS: %4 | Out: %5 | Protected: %6 | Culled: %7 | Override: %8 | Total: %9 | SrvFPS: %10",
            _activeCount, AIC_maxActiveAI,
            count _inRangeLOS, count _inRangeNoLOS,
            count _outOfRange, _protectedCount, _culledCount, _overrideCount,
            _totalAI, AIC_serverFPS
        ];
    };

    [_activeCount, count _inRangeLOS, count _inRangeNoLOS, count _outOfRange, _protectedCount, _culledCount, _overrideCount, _totalAI, AIC_serverFPS]
        call AIC_fnc_broadcastStats;

    sleep AIC_checkInterval;
};
