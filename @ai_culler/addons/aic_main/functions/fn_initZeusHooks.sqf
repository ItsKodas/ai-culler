if (!hasInterface) exitWith {};

// Status window lifecycle: poll for Zeus display opening and closing
[] spawn {
    while {true} do {
        waitUntil { !isNull (findDisplay 312) };
        [findDisplay 312] call AIC_fnc_createStatusWindow;

        // Refresh unit labels for units already in a culled or protected state
        { if (alive _x && _x isKindOf "Man" && !isPlayer _x) then { [_x] call AIC_fnc_updateUnitLabel; }; } forEach allUnits;

        waitUntil { isNull (findDisplay 312) };
    };
};
