// AIC_fnc_clientLoop — registers the per-frame culling handler
if (!hasInterface) exitWith {};
if (!isNil "AIC_clientPFH") exitWith {};            // already running, don't double-register

if (isNil "AIC_clientBudget") then { AIC_clientBudget = 25 };
AIC_clientHidden      = [];   // committed hidden set (persists across ticks)
AIC_clientQueue       = [];   // current sweep's work list (far candidates, snapshot at sweep start)
AIC_clientCursor      = 0;    // index into the queue
AIC_clientSweepHidden = [];   // hidden set being built up during the current sweep

AIC_clientPFH = [{
    // --- Disabled: reveal everything, idle cheaply, keep the handler alive ---
    if (!AIC_clientEnabled) exitWith {
        { if (!isNull _x) then { _x hideObject false } } forEach AIC_clientHidden;
        { if (!isNull _x) then { _x hideObject false } } forEach AIC_clientSweepHidden;
        AIC_clientHidden = []; AIC_clientQueue = []; AIC_clientCursor = 0; AIC_clientSweepHidden = [];
        private _dc = findDisplay 46 displayCtrl 9320;
        if (!isNull _dc) then { ctrlDelete _dc };
    };

    // --- Zeus camera: seeing the field from above, never cull ---
    if (!isNull (findDisplay 312)) exitWith {
        { if (!isNull _x) then { _x hideObject false } } forEach AIC_clientHidden;
        { if (!isNull _x) then { _x hideObject false } } forEach AIC_clientSweepHidden;
        AIC_clientHidden = []; AIC_clientQueue = []; AIC_clientCursor = 0; AIC_clientSweepHidden = [];
    };

    private _playerEyePos = eyePos player;

    private _ads = (inputAction "zoomTemp" > 0) || (inputAction "opticsTemp" > 0) || (cameraView == "GUNNER");
    private _lookDir = [0,0,0];
    if (_ads) then {
        _lookDir = vectorNormalized ((positionCameraToWorld [0,0,1]) vectorDiff (positionCameraToWorld [0,0,0]));
    };

    // --- Cheap, every tick: current candidate pool ---
    private _candidates = allUnits select {
        !isPlayer _x && alive _x && (_x isKindOf "Man") && (_x distance player) < AIC_clientRadius
    };

    // --- Every tick: reveal committed-set units that left the pool or closed inside the safe radius ---
    {
        if (isNull _x) then { continue };
        if (!(_x in _candidates)) then { _x hideObject false; continue };
        if ((_x distance player) <= AIC_clientSafeRadius) then { _x hideObject false };
    } forEach AIC_clientHidden;

    // --- Every tick: reveal and drop mid-sweep hidden units that no longer qualify ---
    // Without this, units hidden during an incomplete sweep can linger invisible until the
    // sweep finishes — the committed-set loop above only covers the previous sweep's units.
    AIC_clientSweepHidden = AIC_clientSweepHidden select {
        private _unit = _x;
        if (isNull _unit || !alive _unit || !(_unit in _candidates) || (_unit distance player) <= AIC_clientSafeRadius) then {
            if (!isNull _unit) then { _unit hideObject false };
            false
        } else {
            true
        };
    };

    // --- Start a new sweep when the previous one finished ---
    if (AIC_clientQueue isEqualTo []) then {
        AIC_clientQueue       = _candidates select { (_x distance player) > AIC_clientSafeRadius };
        AIC_clientCursor      = 0;
        AIC_clientSweepHidden = [];
    };

    // --- Budgeted LOS work: process a slice of the queue this tick ---
    private _end = (AIC_clientCursor + AIC_clientBudget) min (count AIC_clientQueue);
    for "_i" from AIC_clientCursor to (_end - 1) do {
        private _unit = AIC_clientQueue select _i;
        if (isNull _unit || {!alive _unit}) then { continue };

        if ((_unit distance player) <= AIC_clientSafeRadius) then {
            _unit hideObject false;   // moved inside safe radius since the snapshot
        } else {
            private _unitEyePos = eyePos _unit;
            private _blocked    = terrainIntersectASL [_playerEyePos, _unitEyePos];
            if (!_blocked) then {
                private _hits = lineIntersectsObjs [_playerEyePos, _unitEyePos, vehicle player, _unit];
                _blocked = (_hits findIf { !(_x isKindOf "Tree") && !(_x isKindOf "Bush") }) != -1;
            };
            if (_blocked && _ads) then {
                private _toUnit = vectorNormalized (_unitEyePos vectorDiff _playerEyePos);
                if ((_lookDir vectorDotProduct _toUnit) >= 0.866) then { _blocked = false };
            };
            if (_blocked) then {
                _unit hideObject true;
                AIC_clientSweepHidden pushBack _unit;
            } else {
                _unit hideObject false;
            };
        };
    };
    AIC_clientCursor = _end;

    // --- Sweep complete: reconcile committed hidden set, arm the next sweep ---
    if (AIC_clientCursor >= (count AIC_clientQueue)) then {
        {
            if (!isNull _x && {!(_x in AIC_clientSweepHidden)}) then { _x hideObject false };
        } forEach AIC_clientHidden;
        AIC_clientHidden      = AIC_clientSweepHidden;
        AIC_clientSweepHidden = [];   // reset immediately so the cleanup pass above doesn't re-process it next tick
        AIC_clientQueue       = [];
        AIC_clientCursor      = 0;
    };

    // --- Debug HUD ---
    if (AIC_clientDebug) then {
        private _dc = findDisplay 46 displayCtrl 9320;
        if (isNull _dc) then {
            _dc = (findDisplay 46) ctrlCreate ["RscText", 9320];
            if (!isNull _dc) then {
                _dc ctrlSetPosition [safeZoneX + 0.005, safeZoneY + safeZoneH - 0.05, 0.39, 0.033];
                _dc ctrlSetTextColor [1, 1, 0.3, 1];
                _dc ctrlSetBackgroundColor [0, 0, 0, 0.55];
                _dc ctrlShow true;
                _dc ctrlCommit 0;
            };
        };
        if (!isNull _dc) then {
            private _hiddenCount = count AIC_clientHidden;
            private _rendered    = (count _candidates) - _hiddenCount;
            private _adsStr      = if (_ads) then { " [ADS]" } else { "" };
            _dc ctrlSetText format ["CR: %1 vis | %2 hid%3 | sweep %4/%5", _rendered, _hiddenCount, _adsStr, AIC_clientCursor, count AIC_clientQueue];
            _dc ctrlCommit 0;
        };
    } else {
        private _dc = findDisplay 46 displayCtrl 9320;
        if (!isNull _dc) then { ctrlDelete _dc };
    };

}, AIC_clientInterval, []] call CBA_fnc_addPerFrameHandler;
