params ["_activeCount", "_losCount", "_noLosCount", "_outOfRangeCount", "_protectedCount", "_culledCount", "_overrideCount", "_totalAI", "_serverFPS"];

{
    if (isPlayer _x && {!isNull (getAssignedCuratorLogic _x)}) then {
        [_activeCount, _losCount, _noLosCount, _outOfRangeCount, _protectedCount, _culledCount, _overrideCount, _totalAI, _serverFPS]
            remoteExecCall ["AIC_fnc_updateStatusWindow", _x];
    };
} forEach allPlayers;
