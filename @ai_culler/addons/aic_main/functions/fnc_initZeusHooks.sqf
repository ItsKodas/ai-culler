// Context action: toggle culler protection on AI infantry
{
    _x addCuratorContextAction [
        "Toggle Culler Protection",
        { [(_this select 0)] call AIC_fnc_toggleProtection; },
        { (_this select 0) isKindOf "Man" && !isPlayer (_this select 0) && alive (_this select 0) }
    ];
} forEach allCurators;
