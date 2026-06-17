params [["_unit", objNull, [objNull]]];
if (isNull _unit || { !(_unit isKindOf "CAManBase") } || { isPlayer _unit }) exitWith {};
if (!isServer) exitWith { [_unit] remoteExec ["AIC_fnc_protect", 2] };

_unit setVariable ["AIC_zeusProtected", true, true];
if (_unit getVariable ["AIC_disabled", false]) then { [_unit] call AIC_fnc_enableUnit };
[_unit] remoteExec ["AIC_fnc_updateUnitLabel", 0];
if (AIC_debug) then { diag_log format ["[AIC][API] Protected: %1", _unit] };
