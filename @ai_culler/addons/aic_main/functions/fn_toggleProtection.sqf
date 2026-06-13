params ["_unit"];

private _newState = !(_unit getVariable ["zeusProtected", false]);
_unit setVariable ["zeusProtected", _newState, true];

private _msg = format [
    "[AI Culler] %1 — culler protection: %2",
    name _unit,
    if (_newState) then {"ON"} else {"OFF"}
];

[_msg, true] remoteExecCall ["systemChat", remoteExecutedOwner];

if (AIC_debug) then {
    diag_log format ["[AIC] toggled zeusProtected on %1 -> %2", _unit, _newState];
};
