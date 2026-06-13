params ["_unit"];

if (_unit getVariable ["AIC_disabled", false]) then {
    _unit enableSimulationGlobal true;
    _unit enableAI "ALL";
    _unit setVariable ["AIC_disabled", false];

    [_unit] remoteExec ["AIC_fnc_updateUnitLabel", 0];

    if (AIC_debug) then { diag_log format ["[AIC] Enabled: %1", _unit]; };
};
