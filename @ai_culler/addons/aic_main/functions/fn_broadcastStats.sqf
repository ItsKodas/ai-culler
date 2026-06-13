params ["_activeCount", "_losCount", "_noLosCount", "_outOfRangeCount", "_protectedCount", "_culledCount"];

{
    if (isPlayer _x && {!isNull (getAssignedCuratorLogic _x)}) then {
        [_activeCount, _losCount, _noLosCount, _outOfRangeCount, _protectedCount, _culledCount]
            remoteExecCall ["AIC_fnc_updateStatusWindow", _x];
    };
} forEach allPlayers;
