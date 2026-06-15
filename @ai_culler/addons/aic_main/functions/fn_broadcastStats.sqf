params ["_activeCount", "_losCount", "_noLosCount", "_outOfRangeCount", "_protectedCount", "_culledCount", "_overrideCount", "_totalAI", "_serverFPS"];

{
    private _player = getAssignedCuratorUnit _x;
    if (!isNull _player && { isPlayer _player }) then {
        [_activeCount, _losCount, _noLosCount, _outOfRangeCount, _protectedCount, _culledCount, _overrideCount, _totalAI, _serverFPS]
            remoteExecCall ["AIC_fnc_updateStatusWindow", _player];
    };
} forEach allCurators;
