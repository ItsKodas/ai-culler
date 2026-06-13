params ["_display"];

if (isNull _display) exitWith {};

// Remove existing controls (idempotent)
{ ctrlDelete (_display displayCtrl _x); } forEach [9200,9201,9202,9203,9204,9205,9206,9207,9208,9209,9210,9211,9212,9213,9214,9215,9216,9217,9218,9219,9220];

private _wx = safeZoneX + 0.35;
private _y  = safeZoneY + 0.07;
private _w  = 0.255;
private _rH = 0.033;
private _tH = 0.036;

// Background — 7 rows when settings closed, 13 when settings open
private _bg = _display ctrlCreate ["RscText", 9200];
_bg ctrlSetPosition [_wx, _y, _w, _tH + (_rH * 7) + 0.012];
_bg ctrlSetBackgroundColor [0, 0, 0, 0.78];
_bg ctrlCommit 0;

// Title
private _title = _display ctrlCreate ["RscText", 9201];
_title ctrlSetPosition [_wx + 0.005, _y + 0.003, _w - 0.045, _tH - 0.006];
_title ctrlSetText "AI Culler";
_title ctrlSetBackgroundColor [0.12, 0.12, 0.12, 1];
_title ctrlCommit 0;

// Collapse/expand button
private _collapseBtn = _display ctrlCreate ["RscButton", 9202];
_collapseBtn ctrlSetPosition [_wx + _w - 0.042, _y + 0.002, 0.037, _tH - 0.004];
_collapseBtn ctrlSetText "^";
_collapseBtn ctrlSetTextColor [1, 1, 1, 1];
_collapseBtn ctrlSetBackgroundColor [0.25, 0.25, 0.25, 1];
_collapseBtn ctrlCommit 0;
_collapseBtn setVariable ["AIC_collapsed", false];

_collapseBtn ctrlAddEventHandler ["ButtonClick", {
    params ["_btn"];
    private _disp     = ctrlParent _btn;
    private _collapse = !(_btn getVariable ["AIC_collapsed", false]);
    _btn setVariable ["AIC_collapsed", _collapse];
    _btn ctrlSetText (if (_collapse) then {"v"} else {"^"});
    _btn ctrlCommit 0;

    if (_collapse) then {
        { (_disp displayCtrl _x) ctrlShow false; (_disp displayCtrl _x) ctrlCommit 0; }
            forEach [9203,9204,9205,9206,9207,9208,9209,9210,9211,9212,9213,9214,9215,9216,9217,9218,9219,9220];
    } else {
        { (_disp displayCtrl _x) ctrlShow true; (_disp displayCtrl _x) ctrlCommit 0; }
            forEach [9203,9204,9205,9206,9207,9208,9209];
        if ((_disp displayCtrl 9209) getVariable ["AIC_settingsOpen", false]) then {
            { (_disp displayCtrl _x) ctrlShow true; (_disp displayCtrl _x) ctrlCommit 0; }
                forEach [9210,9211,9212,9213,9214,9215,9216,9217,9218,9219,9220];
        };
    };

    private _bg2   = _disp displayCtrl 9200;
    private _pos   = ctrlPosition _bg2;
    private _tH2   = 0.036;
    private _rH2   = 0.033;
    private _sOpen = (_disp displayCtrl 9209) getVariable ["AIC_settingsOpen", false];
    _bg2 ctrlSetPosition [
        _pos select 0, _pos select 1, _pos select 2,
        if (_collapse) then {
            _tH2 + 0.004
        } else {
            if (_sOpen) then {_tH2 + (_rH2 * 13) + 0.012} else {_tH2 + (_rH2 * 7) + 0.012}
        }
    ];
    _bg2 ctrlCommit 0;
}];

// Stat row labels (rows 0–4)
private _labels = ["Active: -- / --", "LOS: --", "No-LOS: --", "Culled: --", "Protected: --"];
private _idcs   = [9203, 9204, 9205, 9206, 9207];

{
    private _ctrl = _display ctrlCreate ["RscText", _idcs select _forEachIndex];
    _ctrl ctrlSetPosition [_wx + 0.007, _y + _tH + 0.006 + (_rH * _forEachIndex), _w - 0.014, _rH - 0.004];
    _ctrl ctrlSetText _x;
    _ctrl ctrlCommit 0;
} forEach _labels;

// Enable/Disable culler toggle button (row 5)
private _toggleBtn = _display ctrlCreate ["RscButton", 9208];
_toggleBtn ctrlSetPosition [_wx + 0.007, _y + _tH + 0.006 + (_rH * 5), _w - 0.014, _rH - 0.004];
_toggleBtn ctrlSetText (if (AIC_cullerEnabled) then {"Disable Culler"} else {"Enable Culler"});
_toggleBtn ctrlCommit 0;

_toggleBtn ctrlAddEventHandler ["ButtonClick", {
    params ["_btn"];
    private _newState = !AIC_cullerEnabled;
    [_newState] remoteExecCall ["AIC_fnc_setCullerEnabled", 2];
    _btn ctrlSetText (if (_newState) then {"Disable Culler"} else {"Enable Culler"});
    _btn ctrlCommit 0;
}];

// Settings toggle button (row 6)
private _settingsToggle = _display ctrlCreate ["RscButton", 9209];
_settingsToggle ctrlSetPosition [_wx + 0.007, _y + _tH + 0.006 + (_rH * 6), _w - 0.014, _rH - 0.004];
_settingsToggle ctrlSetText "Settings";
_settingsToggle ctrlCommit 0;
_settingsToggle setVariable ["AIC_settingsOpen", false];

_settingsToggle ctrlAddEventHandler ["ButtonClick", {
    params ["_btn"];
    private _disp = ctrlParent _btn;
    private _open = !(_btn getVariable ["AIC_settingsOpen", false]);
    _btn setVariable ["AIC_settingsOpen", _open];

    if (_open) then {
        (_disp displayCtrl 9211) ctrlSetText str AIC_maxActiveAI;
        (_disp displayCtrl 9213) ctrlSetText str AIC_distOpfor;
        (_disp displayCtrl 9215) ctrlSetText str AIC_distIndependent;
        (_disp displayCtrl 9217) ctrlSetText str AIC_distCivilian;
        (_disp displayCtrl 9219) ctrlSetText str AIC_checkInterval;
    };

    { (_disp displayCtrl _x) ctrlShow _open; (_disp displayCtrl _x) ctrlCommit 0; }
        forEach [9210,9211,9212,9213,9214,9215,9216,9217,9218,9219,9220];

    private _bg3  = _disp displayCtrl 9200;
    private _pos3 = ctrlPosition _bg3;
    private _tH3  = 0.036;
    private _rH3  = 0.033;
    _bg3 ctrlSetPosition [
        _pos3 select 0, _pos3 select 1, _pos3 select 2,
        if (_open) then {_tH3 + (_rH3 * 13) + 0.012} else {_tH3 + (_rH3 * 7) + 0.012}
    ];
    _bg3 ctrlCommit 0;
}];

// Settings sub-section — label + edit pairs, rows 7–11 (initially hidden)
private _settingsDefs = [
    ["Max AI:",      9210, 9211],
    ["Dist OPFOR:",  9212, 9213],
    ["Dist Indep:",  9214, 9215],
    ["Dist Civ:",    9216, 9217],
    ["Interval(s):", 9218, 9219]
];
private _lW = 0.135;
private _eX = _wx + 0.007 + _lW + 0.004;
private _eW = _w - 0.007 - _lW - 0.004 - 0.007;

{
    _x params ["_lbl", "_lIDC", "_eIDC"];
    private _rowY = _y + _tH + 0.006 + (_rH * (_forEachIndex + 7));

    private _lblCtrl = _display ctrlCreate ["RscText", _lIDC];
    _lblCtrl ctrlSetPosition [_wx + 0.007, _rowY, _lW, _rH - 0.004];
    _lblCtrl ctrlSetText _lbl;
    _lblCtrl ctrlCommit 0;
    _lblCtrl ctrlShow false;
    _lblCtrl ctrlCommit 0;

    private _edtCtrl = _display ctrlCreate ["RscEdit", _eIDC];
    _edtCtrl ctrlSetPosition [_eX, _rowY, _eW, _rH - 0.004];
    _edtCtrl ctrlSetText "";
    _edtCtrl ctrlCommit 0;
    _edtCtrl ctrlShow false;
    _edtCtrl ctrlCommit 0;
} forEach _settingsDefs;

// Apply button (row 12, initially hidden)
private _applyBtn = _display ctrlCreate ["RscButton", 9220];
_applyBtn ctrlSetPosition [_wx + 0.007, _y + _tH + 0.006 + (_rH * 12), _w - 0.014, _rH - 0.004];
_applyBtn ctrlSetText "Apply";
_applyBtn ctrlCommit 0;
_applyBtn ctrlShow false;
_applyBtn ctrlCommit 0;

_applyBtn ctrlAddEventHandler ["ButtonClick", {
    params ["_btn"];
    private _disp     = ctrlParent _btn;
    private _maxAI    = parseNumber ctrlText (_disp displayCtrl 9211);
    private _distO    = parseNumber ctrlText (_disp displayCtrl 9213);
    private _distI    = parseNumber ctrlText (_disp displayCtrl 9215);
    private _distC    = parseNumber ctrlText (_disp displayCtrl 9217);
    private _interval = parseNumber ctrlText (_disp displayCtrl 9219);
    [_maxAI, _distO, _distI, _distC, _interval] remoteExecCall ["AIC_fnc_applySettings", 2];
}];
