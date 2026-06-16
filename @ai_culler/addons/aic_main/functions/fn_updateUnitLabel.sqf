params ["_units"];
if (!(_units isEqualType [])) then { _units = [_units] };
if (!hasInterface || { isNull (getAssignedCuratorLogic player) }) exitWith {};

{
    private _unit = _x;
    if (isNull _unit) then { continue };

    private _protected = _unit getVariable ["AIC_zeusProtected", false];
    private _culled    = _unit getVariable ["AIC_disabled",  false];
    private _override  = !_culled && !_protected && (group _unit) getVariable ["AIC_zeusWaypoint", false];

    private _origName = _unit getVariable ["AIC_origName", ""];
    if (_origName isEqualTo "") then {
        _origName = name _unit;
        _unit setVariable ["AIC_origName", _origName];
    };

    // When labels are disabled restore the plain name; prefix is always empty.
    private _prefix = "";
    if (AIC_showLabels) then {
        if (_culled)    then { _prefix = "[Culled] " };
        if (_override)  then { _prefix = "[Override] " };
        if (_protected) then { _prefix = "[Protected] " };
    };
    _unit setName (_prefix + _origName);
} forEach _units;
