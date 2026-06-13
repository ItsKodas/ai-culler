// Context action: toggle culler protection on AI infantry
{
    _x addCuratorContextAction [
        "Toggle Culler Protection",
        { [(_this select 0)] call AIC_fnc_toggleProtection; },
        { (_this select 0) isKindOf "Man" && !isPlayer (_this select 0) && alive (_this select 0) }
    ];
} forEach allCurators;

// Status window lifecycle: poll for Zeus display opening and closing
[] spawn {
    while {true} do {
        waitUntil { !isNull (findDisplay 312) };
        [findDisplay 312] call AIC_fnc_createStatusWindow;
        waitUntil { isNull (findDisplay 312) };
    };
};
