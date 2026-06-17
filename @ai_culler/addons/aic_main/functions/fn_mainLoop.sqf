if !(isServer) exitWith {};

diag_log "[AIC] Starting culler loop";

while {true} do {
    private _allUnitsRaw = allUnits;

    if (!AIC_cullerEnabled) then {
        // Re-enable any units that were disabled before culler was turned off
        private _toEnable = _allUnitsRaw select { _x getVariable ["AIC_disabled", false] };
        [_toEnable, true] call AIC_fnc_setSimulation;
        if (_toEnable isNotEqualTo []) then {
            [_toEnable] remoteExec ["AIC_fnc_updateUnitLabel", 0];
        };
        private _totalAI = { alive _x && {_x isKindOf "CAManBase" && {!isPlayer _x}} } count _allUnitsRaw;
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
        {_x isKindOf "CAManBase" &&
        {vehicle _x == _x &&
        {!isPlayer _x &&
        {_x getVariable ["AIC_zeusProtected", false] &&
        {side _x in [west, east, resistance, civilian]}}}}}
    } count _allUnitsRaw;

    // Managed pool: living AI infantry on foot, unprotected, all factions.
    // vehicle _x == _x excludes crew seated inside vehicles — culling crew breaks the vehicle.
    private _allAI = _allUnitsRaw select {
        alive _x &&
        {_x isKindOf "CAManBase" &&
        {vehicle _x == _x &&
        {!isPlayer _x &&
        {!(_x getVariable ["AIC_zeusProtected", false]) &&
        {side _x in [west, east, resistance, civilian]}}}}}
    };

    private _outOfRange      = [];
    private _inRangeNoLOS    = [];
    private _inRangeLOS      = [];
    private _labelUpdates    = [];
    private _forceActiveGroups = [];

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

        private _nearestDist = selectMin ((_refPoints apply { _unit distance (_x select 0) }) + [99999]);

        // Combat detection: one nearEntities call, bidirectional group activation,
        // supplemented by behaviour state for units recently in contact.
        private _inCombat = false;
        if (side _unit != civilian) then {
            private _combatEnemies = _unit nearEntities [["CAManBase"], AIC_combatRadius] select {
                alive _x && {!isPlayer _x && {side _x != civilian &&
                {(side _x getFriend side _unit) < 0.6}}}
            };
            if (_combatEnemies isNotEqualTo []) then {
                _inCombat = true;
                { _forceActiveGroups pushBackUnique (group _x) } forEach _combatEnemies;
            };
        };

        if ((group _unit) getVariable ["AIC_zeusWaypoint", false]
            || _inCombat
            || {(group _unit) in _forceActiveGroups}) then {
            _inRangeLOS pushBack _unit;
        } else {
            if (_nearestDist > _cullDist) then {
                // Out of range — cull
                _outOfRange pushBack _unit;
            } else {
                if (_nearestDist <= AIC_minActiveRadius) then {
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
                            _los = (_hits findIf { !(_x isKindOf "Tree") && {!(_x isKindOf "Bush")} }) == -1;
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
        if ((_chunkCount % _chunkSize) == 0 && {_chunkCount < count _allAI}) then { sleep _yieldTime; };
    } forEach _allAI;

    { if (!(_x getVariable ["AIC_disabled", false])) then { _labelUpdates pushBack _x } } forEach _outOfRange;
    [_outOfRange, false] call AIC_fnc_setSimulation;

    { if (_x getVariable ["AIC_disabled", false]) then { _labelUpdates pushBack _x } } forEach _inRangeLOS;
    [_inRangeLOS, true] call AIC_fnc_setSimulation;
    private _activeCount = count _inRangeLOS;

    // Sort ascending by distance so the closest no-LOS units fill the cap first
    _inRangeNoLOS = [_inRangeNoLOS, [], { _x select 1 }, "ASCEND"] call BIS_fnc_sortBy;
    private _noLosEnable  = [];
    private _noLosDisable = [];
    {
        private _unit = _x select 0;
        if (_activeCount < AIC_maxActiveAI) then {
            if (_unit getVariable ["AIC_disabled", false]) then { _labelUpdates pushBack _unit };
            _noLosEnable pushBack _unit;
            _activeCount = _activeCount + 1;
        } else {
            if (!(_unit getVariable ["AIC_disabled", false])) then { _labelUpdates pushBack _unit };
            _noLosDisable pushBack _unit;
        };
    } forEach _inRangeNoLOS;
    [_noLosEnable,  true]  call AIC_fnc_setSimulation;
    [_noLosDisable, false] call AIC_fnc_setSimulation;

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

    AIC_lastStats = createHashMapFromArray [
        ["active",    _activeCount],
        ["los",       count _inRangeLOS],
        ["noLos",     count _inRangeNoLOS],
        ["culled",    _culledCount],
        ["protected", _protectedCount],
        ["override",  _overrideCount],
        ["total",     _totalAI],
        ["serverFps", AIC_serverFPS]
    ];

    [_activeCount, count _inRangeLOS, count _inRangeNoLOS, count _outOfRange, _protectedCount, _culledCount, _overrideCount, _totalAI, AIC_serverFPS]
        call AIC_fnc_broadcastStats;

    sleep AIC_checkInterval;
};
