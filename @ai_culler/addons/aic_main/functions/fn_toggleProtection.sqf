params ["_units"];

if !(_units isEqualType []) then { _units = [_units] };

_units = _units select { alive _x && _x isKindOf "CAManBase" && !isPlayer _x };
if (_units isEqualTo []) exitWith {};

// Smart toggle: protect all if any are unprotected; unprotect all only when all are already protected
private _newState = (_units findIf { !(_x getVariable ["AIC_zeusProtected", false]) }) != -1;

{
    _x setVariable ["AIC_zeusProtected", _newState, true];
    if (_newState && { _x getVariable ["AIC_disabled", false] }) then {
        [_x] call AIC_fnc_enableUnit;
    };
    if (AIC_debug) then {
        diag_log format ["[AIC] AIC_zeusProtected %1 -> %2", _x, _newState];
    };
} forEach _units;

[_units] remoteExec ["AIC_fnc_updateUnitLabel", 0];

private _msg = format ["[AI Culler] %1 unit(s) — protection: %2", count _units, if (_newState) then { "ON" } else { "OFF" }];
[_msg, true] remoteExecCall ["systemChat", remoteExecutedOwner];
