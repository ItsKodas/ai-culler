if (!hasInterface) exitWith {};

while {true} do {
    sleep AIC_clientInterval;

    if (!AIC_clientEnabled) then {
        { hideObject [_x, false]; } forEach AIC_clientHidden;
        AIC_clientHidden = [];
        continue;
    };

    private _playerEyePos = eyePos player;

    // Candidates: living AI infantry within the check radius
    private _candidates = allUnits select {
        !isPlayer _x && alive _x && (_x isKindOf "Man") && (_x distance player) < AIC_clientRadius
    };

    private _newHidden = [];

    {
        private _unit = _x;

        if ((_unit distance player) <= AIC_clientSafeRadius) then {
            // Always visible within safe radius — prevents pop-in as units close distance
            hideObject [_unit, false];
        } else {
            // Terrain is cheaper — check it first
            private _unitEyePos = eyePos _unit;
            private _blocked    = terrainIntersectASL [_playerEyePos, _unitEyePos];

            // If terrain is clear, check solid objects (ignore trees and bushes)
            if (!_blocked) then {
                private _hits = lineIntersectsObjs [_playerEyePos, _unitEyePos, player, _unit];
                _blocked = (_hits findIf { !(_x isKindOf "Tree") && !(_x isKindOf "Bush") }) != -1;
            };

            if (_blocked) then {
                hideObject [_unit, true];
                _newHidden pushBack _unit;
            } else {
                hideObject [_unit, false];
            };
        };
    } forEach _candidates;

    // Re-show units that left the candidate pool this tick (out of range, just died, etc.)
    {
        if !(_x in _candidates) then { hideObject [_x, false]; };
    } forEach AIC_clientHidden;

    AIC_clientHidden = _newHidden;
};
