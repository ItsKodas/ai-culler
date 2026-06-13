params ["_unit"];

if !(_unit getVariable ["AIC_disabled", false]) then {
    _unit disableAI "ALL";
    _unit enableSimulation false;
    _unit setVariable ["AIC_disabled", true];

    private _zeusClients = allPlayers select { isPlayer _x && !isNull (getAssignedCuratorLogic _x) };
    if (count _zeusClients > 0) then {
        [_unit] remoteExec ["AIC_fnc_updateUnitLabel", _zeusClients];
    };

    if (AIC_debug) then { diag_log format ["[AIC] Disabled: %1", _unit]; };
};
