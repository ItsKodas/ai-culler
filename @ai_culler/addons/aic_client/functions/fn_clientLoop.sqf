if (!hasInterface) exitWith {};
params [["_enable", true]];

if (_enable) then {
    if (!isNil "AIC_clientPFH") exitWith {};

    AIC_clientQueue  = [];
    AIC_clientCursor = 0;

    AIC_clientPFH = [{
        params ["_args"];
        _args params ["_lastRun"];

        if (diag_tickTime - _lastRun < 0.05) exitWith {};
        _args set [0, diag_tickTime];

        // Rebuild queue when exhausted
        if (AIC_clientCursor >= count AIC_clientQueue) then {
            private _allUnitsFr = allUnits + allDeadMen + (agents apply {agent _x});
            AIC_clientQueue = _allUnitsFr select {
                !local _x && { _x isKindOf "CAManBase" && { (_x distance player) < AIC_clientRadius } }
            };
            AIC_clientCursor = 0;
        };

        // Size batch to finish the full list in 3 seconds at 20 ticks/sec (60 ticks total)
        private _batchSize = ceil ((count AIC_clientQueue) / 60) max 1;
        private _end = (AIC_clientCursor + _batchSize) min (count AIC_clientQueue);

        // Snapshot local viewers once per batch tick
        private _localPlayerPos = getPosASL player vectorAdd [0, 0, 3];
        private _localAI        = (allUnits select { local _x }) - [player];

        // Terrain-only LOS check — players always see everyone; AI only see enemies
        for "_i" from AIC_clientCursor to (_end - 1) do {
            private _unit = AIC_clientQueue select _i;
            if (isNull _unit) then { continue };
            private _unitAbove  = getPosASL _unit vectorAdd [0, 0, 3];
            private _viewerPos  = [_localPlayerPos] + ((_localAI select { [side group _x, side group _unit] call BIS_fnc_sideIsEnemy }) apply { getPosASL _x vectorAdd [0, 0, 3] });
            private _blocked    = (_viewerPos findIf { !terrainIntersectASL [_x, _unitAbove] }) == -1;
            _unit hideObject _blocked;
        };

        AIC_clientCursor = _end;

    }, 0, [0]] call CBA_fnc_addPerFrameHandler;

} else {
    if (isNil "AIC_clientPFH") exitWith {};

    [AIC_clientPFH] call CBA_fnc_removePerFrameHandler;
    AIC_clientPFH = nil;

    { if (!isNull _x) then { _x hideObject false } } forEach AIC_clientQueue;
    AIC_clientQueue  = [];
    AIC_clientCursor = 0;
};