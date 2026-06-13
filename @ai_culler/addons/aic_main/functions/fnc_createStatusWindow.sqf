params ["_display"];

if (isNull _display) exitWith {};

// Remove existing controls (idempotent)
{ ctrlDelete (_display displayCtrl _x); } forEach [9200,9201,9202,9203,9204,9205,9206,9207,9208];

private _wx = safeZoneX + safeZoneW - 0.265;
private _y  = safeZoneY + 0.025;
private _w  = 0.255;
private _rH = 0.033;
private _tH = 0.036;

// Background
private _bg = _display ctrlCreate ["RscText", 9200];
_bg ctrlSetPosition [_wx, _y, _w, _tH + (_rH * 6) + 0.012];
_bg ctrlSetBackgroundColor [0, 0, 0, 0.78];
_bg ctrlCommit 0;

// Title
private _title = _display ctrlCreate ["RscText", 9201];
_title ctrlSetPosition [_wx + 0.005, _y + 0.003, _w - 0.045, _tH - 0.006];
_title ctrlSetText "AI Culler";
_title ctrlSetBackgroundColor [0.12, 0.12, 0.12, 1];
_title ctrlCommit 0;

// Collapse/expand button
private _btn = _display ctrlCreate ["RscButton", 9202];
_btn ctrlSetPosition [_wx + _w - 0.042, _y + 0.002, 0.037, _tH - 0.004];
_btn ctrlSetText "▲";
_btn ctrlCommit 0;
_btn setVariable ["AIC_collapsed", false];

_btn ctrlAddEventHandler ["ButtonClick", {
    params ["_btn"];
    private _disp     = ctrlParent _btn;
    private _collapse = !(_btn getVariable ["AIC_collapsed", false]);
    _btn setVariable ["AIC_collapsed", _collapse];
    _btn ctrlSetText if (_collapse) then {"▼"} else {"▲"};
    _btn ctrlCommit 0;

    { (_disp displayCtrl _x) ctrlShow !_collapse; (_disp displayCtrl _x) ctrlCommit 0; }
        forEach [9203,9204,9205,9206,9207,9208];

    private _bg2 = _disp displayCtrl 9200;
    private _pos = ctrlPosition _bg2;
    private _tH2 = 0.036;
    private _rH2 = 0.033;
    _bg2 ctrlSetPosition [
        _pos select 0, _pos select 1, _pos select 2,
        if (_collapse) then {_tH2 + 0.004} else {_tH2 + (_rH2 * 6) + 0.012}
    ];
    _bg2 ctrlCommit 0;
}];

// Stat row labels
private _labels = ["Active: -- / --", "LOS: --", "No-LOS: --", "Culled: --", "Protected: --"];
private _idcs   = [9203, 9204, 9205, 9206, 9207];

{
    private _ctrl = _display ctrlCreate ["RscText", _idcs select _forEachIndex];
    _ctrl ctrlSetPosition [_wx + 0.007, _y + _tH + 0.006 + (_rH * _forEachIndex), _w - 0.014, _rH - 0.004];
    _ctrl ctrlSetText _x;
    _ctrl ctrlCommit 0;
} forEach _labels;

// Enable/Disable culler toggle button (row 5, below stat labels)
private _toggleBtn = _display ctrlCreate ["RscButton", 9208];
_toggleBtn ctrlSetPosition [_wx + 0.007, _y + _tH + 0.006 + (_rH * 5), _w - 0.014, _rH - 0.004];
_toggleBtn ctrlSetText if (AIC_cullerEnabled) then {"Disable Culler"} else {"Enable Culler"};
_toggleBtn ctrlCommit 0;

_toggleBtn ctrlAddEventHandler ["ButtonClick", {
    params ["_btn"];
    // Toggle the global on the server
    private _newState = !AIC_cullerEnabled;
    [_newState] remoteExecCall ["AIC_fnc_setCullerEnabled", 2];
    // Update button text locally immediately for responsiveness
    _btn ctrlSetText if (_newState) then {"Disable Culler"} else {"Enable Culler"};
    _btn ctrlCommit 0;
}];
