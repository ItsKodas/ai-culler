params ["_unit"];
if (isNull _unit) exitWith {};
if (!hasInterface || isNull (getAssignedCuratorLogic player)) exitWith {};

private _protected = _unit getVariable ["zeusProtected", false];
private _culled    = _unit getVariable ["AIC_disabled",  false];

private _origName = _unit getVariable ["AIC_origName", ""];
if (_origName isEqualTo "") then {
    _origName = name _unit;
    _unit setVariable ["AIC_origName", _origName];
};

private _prefix = "";
if (_culled)    then { _prefix = "[Culled] "; };
if (_protected) then { _prefix = "[Protected] "; };
_unit setName (_prefix + _origName);
