// Client renderer supports two scenarios:
//   A) Singleplayer — local AI, hideObject has no network side-effects
//   B) Dedicated server MP — AI are remote (server-local), !local _x filter keeps host queue empty
// Host-client (listen server) is NOT supported: host owns AI locally, so hideObject propagates to all clients.
if (!hasInterface) exitWith {};
params [["_enable", true]];

private _isSP = !isMultiplayer;

// Standalone HUD PFH — runs regardless of main loop state
private _fnStartHud = {
    if (!isNil "AIC_clientHudPFH") exitWith {};
    AIC_clientHudPFH = [{
        if (!AIC_clientDebug) exitWith {
            private _dc = findDisplay 46 displayCtrl 9320;
            if (!isNull _dc) then { ctrlDelete _dc };
        };
        private _dc = findDisplay 46 displayCtrl 9320;
        if (isNull _dc) then {
            _dc = (findDisplay 46) ctrlCreate ["RscText", 9320];
            if (!isNull _dc) then {
                _dc ctrlSetPosition [safeZoneX + 0.005, safeZoneY + safeZoneH - 0.05, 0.663, 0.033];
                _dc ctrlSetTextColor [1, 1, 0.3, 1];
                _dc ctrlSetBackgroundColor [0, 0, 0, 0.55];
                _dc ctrlShow true;
                _dc ctrlCommit 0;
            };
        };
        if (!isNull _dc) then {
            private _fpsRatio = if (diag_fps > 0) then { round ((diag_fpsmin / diag_fps) * 100) } else { 0 };
            if (!isNil "AIC_clientPFH") then {
                private _hiddenCount = { isObjectHidden _x } count AIC_clientQueue;
                _dc ctrlSetText format ["CR:%1v %2h | fps%3 min%4 d%5 r%6% | sweep%7/%8 batch%9",
                    (count AIC_clientQueue) - _hiddenCount, _hiddenCount,
                    round diag_fps, round diag_fpsmin,
                    round (diag_fps - diag_fpsmin), _fpsRatio,
                    AIC_clientCursor, count AIC_clientQueue, AIC_clientBatchSize];
            } else {
                _dc ctrlSetText format ["CR:DISABLED | fps%1 min%2 d%3 r%4%",
                    round diag_fps, round diag_fpsmin,
                    round (diag_fps - diag_fpsmin), _fpsRatio];
            };
            _dc ctrlCommit 0;
        };
    }, 0, []] call CBA_fnc_addPerFrameHandler;
};

if (_enable) then {
    if (!isNil "AIC_clientPFH") exitWith {};

    AIC_clientQueue     = [];
    AIC_clientCursor    = 0;
    AIC_clientBatchSize = 0;

    AIC_clientPFH = [
        if (_isSP) then {
            // SP loop — all AI are local, single viewer (player only)
            {
                params ["_args"];
                _args params ["_lastRun"];

                if (diag_tickTime - _lastRun < 0.05) exitWith {};
                _args set [0, diag_tickTime];

                if (AIC_clientCursor >= count AIC_clientQueue) then {
                    AIC_clientQueue = (allUnits + allDeadMen) select {
                        !isPlayer _x && { _x isKindOf "CAManBase" && { vehicle _x == _x && { (_x distance player) < AIC_clientRadius } } }
                    };
                    AIC_clientCursor = 0;
                };

                AIC_clientBatchSize = ceil ((count AIC_clientQueue) / 60) max 1;
                private _end = (AIC_clientCursor + AIC_clientBatchSize) min (count AIC_clientQueue);

                private _localPlayerPos = getPosASL player vectorAdd [0, 0, 3];

                for "_i" from AIC_clientCursor to (_end - 1) do {
                    private _unit = AIC_clientQueue select _i;
                    if (isNull _unit) then { continue };
                    private _unitAbove = getPosASL _unit vectorAdd [0, 0, 3];
                    _unit hideObject (terrainIntersectASL [_localPlayerPos, _unitAbove]);
                };

                AIC_clientCursor = _end;
            }
        } else {
            // MP loop — units are server-local, multiple viewers (player + local hostile AI)
            {
                params ["_args"];
                _args params ["_lastRun"];

                if (diag_tickTime - _lastRun < 0.05) exitWith {};
                _args set [0, diag_tickTime];

                if (AIC_clientCursor >= count AIC_clientQueue) then {
                    private _allUnitsFr = allUnits + allDeadMen + (agents apply {agent _x});
                    AIC_clientQueue = _allUnitsFr select {
                        !local _x && { _x isKindOf "CAManBase" && { (_x distance player) < AIC_clientRadius } }
                    };
                    AIC_clientCursor = 0;
                };

                AIC_clientBatchSize = ceil ((count AIC_clientQueue) / 60) max 1;
                private _end = (AIC_clientCursor + AIC_clientBatchSize) min (count AIC_clientQueue);

                private _localPlayerPos = getPosASL player vectorAdd [0, 0, 3];
                private _localAI        = (allUnits select { local _x }) - [player];

                for "_i" from AIC_clientCursor to (_end - 1) do {
                    private _unit = AIC_clientQueue select _i;
                    if (isNull _unit) then { continue };
                    private _unitAbove  = getPosASL _unit vectorAdd [0, 0, 3];
                    private _viewerPos  = [_localPlayerPos] + ((_localAI select { [side group _x, side group _unit] call BIS_fnc_sideIsEnemy }) apply { getPosASL _x vectorAdd [0, 0, 3] });
                    private _blocked    = (_viewerPos findIf { !terrainIntersectASL [_x, _unitAbove] }) == -1;
                    _unit hideObject _blocked;
                };

                AIC_clientCursor = _end;
            }
        },
        0, [0]
    ] call CBA_fnc_addPerFrameHandler;

    call _fnStartHud;

} else {
    if (isNil "AIC_clientPFH") exitWith {};

    [AIC_clientPFH] call CBA_fnc_removePerFrameHandler;
    AIC_clientPFH = nil;

    { if (!isNull _x) then { _x hideObject false } } forEach AIC_clientQueue;
    AIC_clientQueue     = [];
    AIC_clientCursor    = 0;
    AIC_clientBatchSize = 0;

    call _fnStartHud;
};
