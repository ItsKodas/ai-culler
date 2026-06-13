params ["_activeCount", "_losCount", "_noLosCount", "_outOfRangeCount", "_protectedCount", "_culledCount"];

private _display = findDisplay 312;
if (isNull _display) exitWith {};

private _texts = [
    format ["Active: %1 / %2", _activeCount, AIC_maxActiveAI],
    format ["LOS: %1",         _losCount],
    format ["No-LOS: %1",      _noLosCount],
    format ["Culled: %1",      _culledCount],
    format ["Protected: %1",   _protectedCount]
];

{
    private _ctrl = _display displayCtrl ([9203,9204,9205,9206,9207] select _forEachIndex);
    if (!isNull _ctrl) then {
        _ctrl ctrlSetText _x;
        _ctrl ctrlCommit 0;
    };
} forEach _texts;

// Keep toggle button label in sync with server state
private _toggleBtn = _display displayCtrl 9208;
if (!isNull _toggleBtn) then {
    _toggleBtn ctrlSetText if (AIC_cullerEnabled) then {"Disable Culler"} else {"Enable Culler"};
    _toggleBtn ctrlCommit 0;
};
