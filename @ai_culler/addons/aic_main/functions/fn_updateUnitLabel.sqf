params ["_unit"];
if (isNull _unit) exitWith {};
private _protected = _unit getVariable ["zeusProtected", false];
private _culled    = _unit getVariable ["AIC_disabled",  false];
private _label = if (_protected) then { "Protected" } else { if (_culled) then { "Culled" } else { "" } };
_unit setObjectText _label;
