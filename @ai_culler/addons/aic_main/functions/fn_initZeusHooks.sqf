if (!hasInterface) exitWith {};

// Status window lifecycle: poll for Zeus display opening and closing
[] spawn {
    while {true} do {
        waitUntil { !isNull (findDisplay 312) };
        [findDisplay 312] call AIC_fnc_createStatusWindow;
        waitUntil { isNull (findDisplay 312) };
    };
};
