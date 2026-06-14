if (!hasInterface) exitWith {};

while {true} do {
    sleep AIC_clientInterval;

    if (!AIC_clientEnabled) then {
        { _x hideObject false; } forEach AIC_clientHidden;
        AIC_clientHidden = [];
        private _dc = findDisplay 46 displayCtrl 9320; if (!isNull _dc) then { ctrlDelete _dc; };
        continue;
    };

    private _playerEyePos = eyePos player;

    // ADS cone: when aiming down sights, units aimed at are force-rendered even if body-occluded
    private _ads     = isAimingDown player;
    private _lookDir = if (_ads) then { eyeDirection player } else { [0,0,0] };

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
                private _hits = lineIntersectsObjs [_playerEyePos, _unitEyePos, player, _unit];
                _blocked = (_hits findIf { !(_x isKindOf "Tree") && !(_x isKindOf "Bush") }) != -1;
            };

            // ADS cone override: unit is within ~30° of aim direction — render regardless of occlusion
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
            _dc ctrlSetPosition [safeZoneX + 0.005, safeZoneY + safeZoneH - 0.038, 0.22, 0.033];
            _dc ctrlSetTextColor [1, 1, 0.3, 1];
            _dc ctrlSetBackgroundColor [0, 0, 0, 0.55];
            _dc ctrlCommit 0;
        };
        private _rendered = (count _candidates) - (count _newHidden);
        _dc ctrlSetText format ["CR: %1 visible | %2 hidden", _rendered, count _newHidden];
        _dc ctrlCommit 0;
    } else {
        private _dc = findDisplay 46 displayCtrl 9320; if (!isNull _dc) then { ctrlDelete _dc; };
    };
};
