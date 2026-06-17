params ["_units", ["_enable", true]];

if !(_units isEqualType []) then { _units = [_units] };

{
    if ((_x getVariable ["AIC_disabled", false]) != _enable) exitWith {};
    if (!_enable) then { _x setVariable ["AIC_wasSimEnabled", simulationEnabled _x] };
    _x enableSimulationGlobal (_enable && (_x getVariable ["AIC_wasSimEnabled", true]));
    _x setVariable ["AIC_disabled", !_enable, true];
    if (AIC_debug) then { diag_log format ["[AIC] %1: %2", ["Disabled","Enabled"] select _enable, _x]; };
} forEach _units;
