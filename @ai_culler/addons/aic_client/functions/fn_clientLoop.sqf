// Client renderer supports two scenarios:
//   A) Singleplayer — local AI, hideObject has no network side-effects
//   B) Dedicated server MP — AI are remote (server-local), !local _x filter keeps host queue empty
// Host-client (listen server) is NOT supported: host owns AI locally, so hideObject propagates to all clients.
if (!hasInterface) exitWith {};
params [["_enable", true]];

private _isSP = !isMultiplayer;

// Only reveal a unit if aic_client was the one that hid it. This prevents us from
// calling hideObject false on units hidden by other mods (e.g. Hide Zeus module),
// which would override their hideObjectGlobal on this client.
private _fnReveal = {
    params ["_u"];
    if (_u getVariable ["AIC_clientHid", false]) then {
        _u hideObject false;
        _u setVariable ["AIC_clientHid", false];
    };
};
private _fnHide = {
    params ["_u"];
    _u hideObject true;
    _u setVariable ["AIC_clientHid", true];
};

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
                _dc ctrlSetText format ["CR:%1v %2h | fps%3 min%4 d%5 r%6% | sweep%7/%8 batch%9%10",
                    (count AIC_clientQueue) - _hiddenCount, _hiddenCount,
                    round diag_fps, round diag_fpsmin,
                    round (diag_fps - diag_fpsmin), _fpsRatio,
                    AIC_clientCursor, count AIC_clientQueue, AIC_clientBatchSize,
                    if (AIC_clientADS) then { " [ADS]" } else { "" }];
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

                if (!isNull (remoteControlled player)) exitWith {
                    { [_x] call _fnReveal } forEach AIC_clientQueue;
                };

                if (AIC_clientCursor >= count AIC_clientQueue) then {
                    AIC_clientQueue = (allUnits + allDeadMen) select {
                        !isPlayer _x && { _x isKindOf "CAManBase" && { vehicle _x == _x && { (_x distance player) < AIC_clientRadius } } }
                    };
                    AIC_clientCursor = 0;
                };

                AIC_clientBatchSize = ceil ((count AIC_clientQueue) / 60) max 1;
                private _end = (AIC_clientCursor + AIC_clientBatchSize) min (count AIC_clientQueue);

                private _inZeus     = !isNull (findDisplay 312);
                private _localPlayerPos = getPosASL player vectorAdd [0, 0, 3];
                private _ads     = (inputAction "zoomTemp" > 0) || { (inputAction "opticsTemp" > 0) || { cameraView == "GUNNER" } };
                AIC_clientADS    = _ads;
                private _lookDir = if (_ads) then { vectorNormalized ((positionCameraToWorld [0,0,1]) vectorDiff (positionCameraToWorld [0,0,0])) } else { [0,0,0] };

                for "_i" from AIC_clientCursor to (_end - 1) do {
                    private _unit = AIC_clientQueue select _i;
                    if (isNull _unit) then { continue };
                    if (!isNull (remoteControlled _unit)) then { [_unit] call _fnReveal; continue };
                    if (_inZeus) then { [_unit] call _fnReveal; continue };
                    if (!alive _unit) then {
                        private _shouldHide = AIC_clientCorpseRadius > 0 && { (_unit distance player) > AIC_clientCorpseRadius };
                        if (_shouldHide) then { [_unit] call _fnHide } else { [_unit] call _fnReveal };
                        continue
                    };
                    if ((_unit distance player) <= AIC_clientSafeRadius) then { [_unit] call _fnReveal; continue };
                    private _unitAbove = getPosASL _unit vectorAdd [0, 0, 3];
                    if (terrainIntersectASL [_localPlayerPos, _unitAbove]) then {
                        [_unit] call _fnHide;
                    } else {
                        if ((_unit distance player) <= AIC_clientSurfaceRadius) then {
                            private _playerEye = eyePos player;
                            private _unitEye   = eyePos _unit;
                            private _hits      = lineIntersectsSurfaces [_playerEye, _unitEye, player, _unit, true, 1, "VIEW"];
                            private _blocked   = (_hits findIf {
                                private _obj = _x select 2;
                                private _type = toLower (typeOf _obj);
                                !isNull _obj && { ((_type find "net") == -1) && { (_type find "bag") == -1 } && { (_type find "bunker") == -1 } }
                            }) != -1;
                            if (_blocked && _ads) then {
                                if ((vectorNormalized (_unitEye vectorDiff _playerEye) vectorDotProduct _lookDir) >= 0.866) then { _blocked = false };
                            };
                            if (_blocked) then { [_unit] call _fnHide } else { [_unit] call _fnReveal };
                        } else {
                            [_unit] call _fnReveal;
                        };
                    };
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

                if (!isNull (remoteControlled player)) exitWith {
                    { [_x] call _fnReveal } forEach AIC_clientQueue;
                };

                if (AIC_clientCursor >= count AIC_clientQueue) then {
                    private _allUnitsFr = allUnits + allDeadMen + (agents apply {agent _x});
                    AIC_clientQueue = _allUnitsFr select {
                        !local _x && { _x isKindOf "CAManBase" && { vehicle _x == _x && { (_x distance player) < AIC_clientRadius } } }
                    };
                    AIC_clientCursor = 0;
                };

                AIC_clientBatchSize = ceil ((count AIC_clientQueue) / 60) max 1;
                private _end = (AIC_clientCursor + AIC_clientBatchSize) min (count AIC_clientQueue);

                private _inZeus     = !isNull (findDisplay 312);
                private _localPlayerPos = getPosASL player vectorAdd [0, 0, 3];
                private _localAI        = (allUnits select { local _x }) - [player];
                private _ads     = (inputAction "zoomTemp" > 0) || { (inputAction "opticsTemp" > 0) || { cameraView == "GUNNER" } };
                AIC_clientADS    = _ads;
                private _lookDir = if (_ads) then { vectorNormalized ((positionCameraToWorld [0,0,1]) vectorDiff (positionCameraToWorld [0,0,0])) } else { [0,0,0] };

                for "_i" from AIC_clientCursor to (_end - 1) do {
                    private _unit = AIC_clientQueue select _i;
                    if (isNull _unit) then { continue };
                    if (!isNull (remoteControlled _unit)) then { [_unit] call _fnReveal; continue };
                    if (_inZeus) then { [_unit] call _fnReveal; continue };
                    if (!alive _unit) then {
                        private _shouldHide = AIC_clientCorpseRadius > 0 && { (_unit distance player) > AIC_clientCorpseRadius };
                        if (_shouldHide) then { [_unit] call _fnHide } else { [_unit] call _fnReveal };
                        continue
                    };
                    if ((_unit distance player) <= AIC_clientSafeRadius) then { [_unit] call _fnReveal; continue };
                    private _unitAbove = getPosASL _unit vectorAdd [0, 0, 3];
                    private _hostileAI = _localAI select { [side group _x, side group _unit] call BIS_fnc_sideIsEnemy };
                    if ((_hostileAI findIf { !terrainIntersectASL [getPosASL _x vectorAdd [0,0,3], _unitAbove] }) != -1) then {
                        [_unit] call _fnReveal; continue;
                    };
                    if (terrainIntersectASL [_localPlayerPos, _unitAbove]) then {
                        [_unit] call _fnHide;
                    } else {
                        if ((_unit distance player) <= AIC_clientSurfaceRadius) then {
                            private _playerEye = eyePos player;
                            private _unitEye   = eyePos _unit;
                            private _hits      = lineIntersectsSurfaces [_playerEye, _unitEye, player, _unit, true, 1, "VIEW"];
                            private _blocked   = (_hits findIf {
                                private _obj = _x select 2;
                                private _type = toLower (typeOf _obj);
                                !isNull _obj && { ((_type find "net") == -1) && { (_type find "bag") == -1 } && { (_type find "bunker") == -1 } }
                            }) != -1;
                            if (_blocked && _ads) then {
                                if ((vectorNormalized (_unitEye vectorDiff _playerEye) vectorDotProduct _lookDir) >= 0.866) then { _blocked = false };
                            };
                            if (_blocked) then { [_unit] call _fnHide } else { [_unit] call _fnReveal };
                        } else {
                            [_unit] call _fnReveal;
                        };
                    };
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

    { if (!isNull _x) then { [_x] call _fnReveal } } forEach AIC_clientQueue;
    AIC_clientQueue     = [];
    AIC_clientCursor    = 0;
    AIC_clientBatchSize = 0;

    call _fnStartHud;
};
