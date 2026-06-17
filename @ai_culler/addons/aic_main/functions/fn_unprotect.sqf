params [["_unit", objNull, [objNull]]];
if (isNull _unit || { !(_unit isKindOf "CAManBase") } || { isPlayer _unit }) exitWith {};
if (!isServer) exitWith { [_unit] remoteExec ["AIC_fnc_unprotect", 2] };

_unit setVariable ["AIC_zeusProtected", false, true];
[_unit] remoteExec ["AIC_fnc_updateUnitLabel", 0];
if (AIC_debug) then { diag_log format ["[AIC][API] Unprotected: %1", _unit] };
