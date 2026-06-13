params ["_units"];

if !(_units isEqualType []) then { _units = [_units]; };

_units = _units select { alive _x && _x isKindOf "Man" && !isPlayer _x };
if (count _units == 0) exitWith {};

private _zeusClients = allPlayers select { isPlayer _x && !isNull (getAssignedCuratorLogic _x) };

{
    private _unit     = _x;
    private _newState = !(_unit getVariable ["zeusProtected", false]);
    _unit setVariable ["zeusProtected", _newState, true];

    if (count _zeusClients > 0) then {
        [_unit] remoteExec ["AIC_fnc_updateUnitLabel", _zeusClients];
    };

    if (AIC_debug) then {
        diag_log format ["[AIC] zeusProtected %1 -> %2", _unit, _newState];
    };
} forEach _units;

private _msg = if (count _units == 1) then {
    private _u = _units select 0;
    format ["[AI Culler] %1 — protection: %2", name _u, if (_u getVariable ["zeusProtected", false]) then {"ON"} else {"OFF"}]
} else {
    format ["[AI Culler] %1 units — protection toggled", count _units]
};
[_msg, true] remoteExecCall ["systemChat", remoteExecutedOwner];
