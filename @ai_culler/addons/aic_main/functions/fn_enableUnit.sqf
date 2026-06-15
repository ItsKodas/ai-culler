params ["_unit"];

if !(_unit getVariable ["AIC_disabled", false]) exitWith {};

_unit enableSimulationGlobal (_unit getVariable ["AIC_wasSimEnabled", true]);
_unit setVariable ["AIC_disabled", false, true];

if (AIC_debug) then { diag_log format ["[AIC] Enabled: %1", _unit]; };
