params ["_unit"];

if (_unit getVariable ["AIC_disabled", false]) exitWith {};

_unit setVariable ["AIC_wasSimEnabled", simulationEnabled _unit];
_unit enableSimulationGlobal false;
_unit setVariable ["AIC_disabled", true, true];

if (AIC_debug) then { diag_log format ["[AIC] Disabled: %1", _unit]; };
