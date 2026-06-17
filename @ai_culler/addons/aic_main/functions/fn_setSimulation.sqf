params ["_units", ["_enable", true]];

if !(_units isEqualType []) then { _units = [_units] };

{
    if (_enable) then {
        if !(_x getVariable ["AIC_disabled", false]) exitWith {};
        _x enableSimulationGlobal (_x getVariable ["AIC_wasSimEnabled", true]);
        _x setVariable ["AIC_disabled", false, true];
        if (AIC_debug) then { diag_log format ["[AIC] Enabled: %1", _x]; };
    } else {
        if (_x getVariable ["AIC_disabled", false]) exitWith {};
        _x setVariable ["AIC_wasSimEnabled", simulationEnabled _x];
        _x enableSimulationGlobal false;
        _x setVariable ["AIC_disabled", true, true];
        if (AIC_debug) then { diag_log format ["[AIC] Disabled: %1", _x]; };
    };
} forEach _units;
