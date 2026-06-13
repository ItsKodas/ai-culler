params ["_unit"];
if (isNull _unit) exitWith {};
if (!hasInterface || isNull (getAssignedCuratorLogic player)) exitWith {};
private _protected = _unit getVariable ["zeusProtected", false];
private _culled    = _unit getVariable ["AIC_disabled",  false];
private _label = "";
if (_culled)    then { _label = "Culled"; };
if (_protected) then { _label = "Protected"; };
_unit setObjectText _label;
