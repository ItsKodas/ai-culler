params ["_unit"];

if !(_unit getVariable ["AIC_disabled", false]) then {
    _unit disableAI "ALL";
    _unit enableSimulationGlobal false;
    _unit setVariable ["AIC_disabled", true, true];

    [_unit] remoteExec ["AIC_fnc_updateUnitLabel", 0];

    if (AIC_debug) then { diag_log format ["[AIC] Disabled: %1", _unit]; };
};
