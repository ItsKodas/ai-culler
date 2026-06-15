if (!hasInterface) exitWith {};

while {true} do {
    sleep AIC_clientInterval;

    if (!AIC_clientEnabled) then {
        { _x hideObject false; } forEach AIC_clientHidden;
        AIC_clientHidden = [];
        private _dc = findDisplay 46 displayCtrl 9320; if (!isNull _dc) then { ctrlDelete _dc; };
        continue;
    };

    // Zeus camera: player sees the battlefield from above — never cull anything
    if (!isNull (findDisplay 312)) then {
        { _x hideObject false; } forEach AIC_clientHidden;
        AIC_clientHidden = [];
        continue;
    };

    private _playerEyePos = eyePos player;

    // ADS cone: active while holding RMB (no optic) or while optic view is toggled on.
    // zoomTemp = Hold RMB precision aim (no optic). cameraView "GUNNER" = player looking through a weapon optic (toggle or hold).
    private _ads = (inputAction "zoomTemp" > 0) || (inputAction "opticsTemp" > 0) || (cameraView == "GUNNER");
    private _lookDir = [0,0,0];
    if (_ads) then {
        _lookDir = vectorNormalized ((positionCameraToWorld [0,0,1]) vectorDiff (positionCameraToWorld [0,0,0]));
    };

    // Candidates: living AI infantry within the check radius
    private _candidates = allUnits select {
        !isPlayer _x && alive _x && (_x isKindOf "Man") && (_x distance player) < AIC_clientRadius
    };

    private _newHidden = [];

    {
        private _unit = _x;

        if ((_unit distance player) <= AIC_clientSafeRadius) then {
            // Always visible within safe radius — prevents pop-in as units close distance
            _unit hideObject false;
        } else {
            // Terrain is cheaper — check it first
            private _unitEyePos = eyePos _unit;
            private _blocked    = terrainIntersectASL [_playerEyePos, _unitEyePos];

            // If terrain is clear, check solid objects (ignore trees and bushes)
            if (!_blocked) then {
                private _hits = lineIntersectsObjs [_playerEyePos, _unitEyePos, vehicle player, _unit];
                _blocked = (_hits findIf { !(_x isKindOf "Tree") && !(_x isKindOf "Bush") }) != -1;
            };

            // ADS cone override: render units within ~30° of aim direction when right mouse is held
            if (_blocked && _ads) then {
                private _toUnit = vectorNormalized (_unitEyePos vectorDiff _playerEyePos);
                if ((_lookDir vectorDotProduct _toUnit) >= 0.866) then { _blocked = false; };
            };

            if (_blocked) then {
                _unit hideObject true;
                _newHidden pushBack _unit;
            } else {
                _unit hideObject false;
            };
        };
    } forEach _candidates;

    // Re-show units that left the candidate pool this tick (out of range, just died, etc.)
    {
        if !(_x in _candidates) then { _x hideObject false; };
    } forEach AIC_clientHidden;

    AIC_clientHidden = _newHidden;

    // Debug HUD — small overlay on the normal player screen
    if (AIC_clientDebug) then {
        private _dc = findDisplay 46 displayCtrl 9320;
        if (isNull _dc) then {
            _dc = (findDisplay 46) ctrlCreate ["RscText", 9320];
            if (!isNull _dc) then {
                _dc ctrlSetPosition [safeZoneX + 0.005, safeZoneY + safeZoneH - 0.05, 0.22, 0.033];
                _dc ctrlSetTextColor [1, 1, 0.3, 1];
                _dc ctrlSetBackgroundColor [0, 0, 0, 0.55];
                _dc ctrlShow true;
                _dc ctrlCommit 0;
            };
        };
        if (!isNull _dc) then {
            private _rendered = (count _candidates) - (count _newHidden);
            private _adsStr = if (_ads) then { " [ADS]" } else { "" };
            _dc ctrlSetText format ["CR: %1 visible | %2 hidden%3", _rendered, count _newHidden, _adsStr];
            _dc ctrlCommit 0;
        };
    } else {
        private _dc = findDisplay 46 displayCtrl 9320; if (!isNull _dc) then { ctrlDelete _dc; };
    };
};
