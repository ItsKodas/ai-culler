// AIC_fnc_clientLoop — registers the adaptive per-frame culling handler
// Design target: ~50-100 AI in radius at the high end.
if (!hasInterface) exitWith {};
if (!isNil "AIC_clientPFH") exitWith {};            // already running, don't double-register

AIC_clientBudget      = AIC_clientBudgetMin;        // current computed slice size (HUD only)
AIC_clientInterval    = AIC_clientIntervalMin;      // current computed cadence (HUD only)
AIC_clientFpsAvg      = diag_fps max AIC_clientFpsTarget;  // seed at target so first tick isn't artificially delayed
AIC_clientHidden      = [];   // committed hidden set (persists across ticks)
AIC_clientQueue       = [];   // current sweep's work list (far candidates, snapshot at sweep start)
AIC_clientCursor      = 0;    // index into the queue
AIC_clientSweepHidden = [];   // hidden set being built up during the current (in-progress) sweep

AIC_clientPFH = [{
    params ["_args"];
    _args params ["_lastRun"];

    // diag_fps is Arma's built-in 16-frame rolling average — no additional smoothing needed
    AIC_clientFpsAvg = diag_fps;

    // Cadence: low FPS backs off, high FPS stays responsive
    AIC_clientInterval = linearConversion [
        AIC_clientFpsFloor, AIC_clientFpsTarget, AIC_clientFpsAvg,
        AIC_clientIntervalMax, AIC_clientIntervalMin, true
    ];

    // Time gate — diag_tickTime is real seconds, immune to pause / time-accel
    if (diag_tickTime - _lastRun < AIC_clientInterval) exitWith {};
    _args set [0, diag_tickTime];

    // --- Disabled: reveal everything (both sets), idle cheaply, keep the handler alive ---
    if (!AIC_clientEnabled) exitWith {
        { if (!isNull _x) then { _x hideObject false } } forEach (AIC_clientHidden + AIC_clientSweepHidden);
        AIC_clientHidden = []; AIC_clientQueue = []; AIC_clientCursor = 0; AIC_clientSweepHidden = [];
        private _dc = findDisplay 46 displayCtrl 9320;
        if (!isNull _dc) then { ctrlDelete _dc };
    };

    // --- Zeus camera: seeing the field from above, never cull ---
    if (!isNull (findDisplay 312)) exitWith {
        { if (!isNull _x) then { _x hideObject false } } forEach (AIC_clientHidden + AIC_clientSweepHidden);
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

    // --- Every tick: reveal from the COMMITTED set (left pool / closed inside safe radius) ---
    {
        if (isNull _x) then { continue };
        if (!(_x in _candidates)) then { _x hideObject false; continue };
        if ((_x distance player) <= AIC_clientSafeRadius) then { _x hideObject false };
    } forEach AIC_clientHidden;

    // --- Every tick: reveal from the IN-PROGRESS sweep set too (closes the mid-sweep gap) + prune ---
    if (AIC_clientSweepHidden isNotEqualTo []) then {
        private _stillHidden = [];
        {
            if (isNull _x) then { continue };
            if (!(_x in _candidates) || { (_x distance player) <= AIC_clientSafeRadius }) then {
                _x hideObject false;
            } else {
                _stillHidden pushBack _x;
            };
        } forEach AIC_clientSweepHidden;
        AIC_clientSweepHidden = _stillHidden;
    };

    // --- Start a new sweep when the previous one finished ---
    if (AIC_clientQueue isEqualTo []) then {
        AIC_clientQueue       = _candidates select { (_x distance player) > AIC_clientSafeRadius };
        AIC_clientCursor      = 0;
        AIC_clientSweepHidden = [];
    };

    // --- Budget: size slices to clear the sweep in ~AIC_clientSweepTicks ticks (scales with pool size).
    //     FPS-floor guard throttles to the slice floor only if frametime is genuinely collapsing. ---
    AIC_clientBudget = ceil ((count AIC_clientQueue) / (AIC_clientSweepTicks max 1));
    if (AIC_clientFpsAvg < AIC_clientFpsFloor) then {
        AIC_clientBudget = AIC_clientBudget min AIC_clientBudgetMin;
    };
    AIC_clientBudget = AIC_clientBudget max 1 min AIC_clientBudgetMax;

    // --- Budgeted LOS work: process a slice of the queue this tick ---
    private _end = (AIC_clientCursor + AIC_clientBudget) min (count AIC_clientQueue);
    for "_i" from AIC_clientCursor to (_end - 1) do {
        private _unit = AIC_clientQueue select _i;
        if (isNull _unit || { !alive _unit }) then { continue };

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

    // --- Sweep complete: reconcile committed set, arm next sweep ---
    if (AIC_clientCursor >= (count AIC_clientQueue)) then {
        {
            if (!isNull _x && { !(_x in AIC_clientSweepHidden) }) then { _x hideObject false };
        } forEach AIC_clientHidden;
        AIC_clientHidden      = AIC_clientSweepHidden;
        AIC_clientSweepHidden = [];
        AIC_clientQueue       = [];
        AIC_clientCursor      = 0;
    };

    // --- Debug HUD ---
    if (AIC_clientDebug) then {
        private _dc = findDisplay 46 displayCtrl 9320;
        if (isNull _dc) then {
            _dc = (findDisplay 46) ctrlCreate ["RscText", 9320];
            if (!isNull _dc) then {
                _dc ctrlSetPosition [safeZoneX + 0.005, safeZoneY + safeZoneH - 0.05, 0.51, 0.033];
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
            _dc ctrlSetText format ["CR:%1v %2h%3 | fps%4 int%5 bud%6 | sweep%7/%8",
                _rendered, _hiddenCount, _adsStr,
                round AIC_clientFpsAvg, (AIC_clientInterval toFixed 2), AIC_clientBudget,
                AIC_clientCursor, count AIC_clientQueue];
            _dc ctrlCommit 0;
        };
    } else {
        private _dc = findDisplay 46 displayCtrl 9320;
        if (!isNull _dc) then { ctrlDelete _dc };
    };

}, 0, [diag_tickTime]] call CBA_fnc_addPerFrameHandler;
