params ["_display"];

if (isNull _display) exitWith {};

// Remove existing controls (idempotent)
{ ctrlDelete (_display displayCtrl _x); } forEach [9200,9201,9202,9203,9204,9205,9206,9207,9208,9209,9210,9211,9212,9213,9214,9215,9216,9217,9218,9219,9220,9221,9222,9223,9224,9225,9226,9227,9228,9229,9230,9231];

private _wx    = safeZoneX + 0.35;
private _y     = safeZoneY + 0.07;
private _w     = 0.29;
private _rH    = 0.033;
private _tH    = 0.036;
private _colW  = 0.118;
private _rColX = _wx + 0.007 + _colW + 0.005;
private _rColW = _w - 0.014 - _colW - 0.005;

// Background — 8 rows when settings closed, 18 when settings open
private _bg = _display ctrlCreate ["RscText", 9200];
_bg ctrlSetPosition [_wx, _y, _w, _tH + (_rH * 8) + 0.012];
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
            forEach [9203,9204,9205,9206,9207,9221,9229,9230,9231,9208,9209,9210,9211,9212,9213,9214,9215,9216,9217,9218,9219,9222,9223,9224,9225,9227,9228,9226,9220];
    } else {
        { (_disp displayCtrl _x) ctrlShow true; (_disp displayCtrl _x) ctrlCommit 0; }
            forEach [9203,9204,9205,9206,9207,9221,9229,9230,9231,9208,9209];
        if ((_disp displayCtrl 9209) getVariable ["AIC_settingsOpen", false]) then {
            { (_disp displayCtrl _x) ctrlShow true; (_disp displayCtrl _x) ctrlCommit 0; }
                forEach [9210,9211,9212,9213,9214,9215,9216,9217,9218,9219,9222,9223,9224,9225,9227,9228,9226,9220];
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
            if (_sOpen) then {_tH2 + (_rH2 * 18) + 0.012} else {_tH2 + (_rH2 * 8) + 0.012}
        }
    ];
    _bg2 ctrlCommit 0;
}];

// Left column: main stat labels (rows 0–5)
private _leftLabels = ["Active: --/--", "LOS: --", "No-LOS: --", "Culled: --", "Protected: --", "Override: --"];
private _leftIdcs   = [9203, 9204, 9205, 9206, 9207, 9221];

{
    private _ctrl = _display ctrlCreate ["RscText", _leftIdcs select _forEachIndex];
    _ctrl ctrlSetPosition [_wx + 0.007, _y + _tH + 0.006 + (_rH * _forEachIndex), _colW, _rH - 0.004];
    _ctrl ctrlSetText _x;
    _ctrl ctrlCommit 0;
} forEach _leftLabels;

// Right column: performance stats (rows 0–2, alongside left column)
private _rightLabels = ["Total AI: --", "Srv FPS: --", "Clt FPS: --"];
private _rightIdcs   = [9229, 9230, 9231];

{
    private _ctrl = _display ctrlCreate ["RscText", _rightIdcs select _forEachIndex];
    _ctrl ctrlSetPosition [_rColX, _y + _tH + 0.006 + (_rH * _forEachIndex), _rColW, _rH - 0.004];
    _ctrl ctrlSetText _x;
    _ctrl ctrlCommit 0;
} forEach _rightLabels;

// Enable/Disable culler toggle button (row 6)
private _toggleBtn = _display ctrlCreate ["RscButton", 9208];
_toggleBtn ctrlSetPosition [_wx + 0.007, _y + _tH + 0.006 + (_rH * 6), _w - 0.014, _rH - 0.004];
_toggleBtn ctrlSetText (if (AIC_cullerEnabled) then {"Disable Culler"} else {"Enable Culler"});
_toggleBtn ctrlCommit 0;

_toggleBtn ctrlAddEventHandler ["ButtonClick", {
    params ["_btn"];
    private _newState = !AIC_cullerEnabled;
    [_newState] remoteExecCall ["AIC_fnc_setCullerEnabled", 2];
    _btn ctrlSetText (if (_newState) then {"Disable Culler"} else {"Enable Culler"});
    _btn ctrlCommit 0;
}];

// Settings toggle button (row 7)
private _settingsToggle = _display ctrlCreate ["RscButton", 9209];
_settingsToggle ctrlSetPosition [_wx + 0.007, _y + _tH + 0.006 + (_rH * 7), _w - 0.014, _rH - 0.004];
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
        (_disp displayCtrl 9213) ctrlSetText str AIC_distBlufor;
        (_disp displayCtrl 9215) ctrlSetText str AIC_distOpfor;
        (_disp displayCtrl 9217) ctrlSetText str AIC_distIndependent;
        (_disp displayCtrl 9219) ctrlSetText str AIC_distCivilian;
        (_disp displayCtrl 9223) ctrlSetText str AIC_checkInterval;
        (_disp displayCtrl 9225) ctrlSetText str AIC_minActiveRadius;
        (_disp displayCtrl 9228) ctrlSetText str AIC_combatRadius;
        (_disp displayCtrl 9226) ctrlSetText (if (AIC_debug) then {"Debug: ON"} else {"Debug: OFF"});
        (_disp displayCtrl 9226) setVariable ["AIC_debugEnabled", AIC_debug];
    };

    { (_disp displayCtrl _x) ctrlShow _open; (_disp displayCtrl _x) ctrlCommit 0; }
        forEach [9210,9211,9212,9213,9214,9215,9216,9217,9218,9219,9222,9223,9224,9225,9227,9228,9226,9220];

    private _bg3  = _disp displayCtrl 9200;
    private _pos3 = ctrlPosition _bg3;
    private _tH3  = 0.036;
    private _rH3  = 0.033;
    _bg3 ctrlSetPosition [
        _pos3 select 0, _pos3 select 1, _pos3 select 2,
        if (_open) then {_tH3 + (_rH3 * 18) + 0.012} else {_tH3 + (_rH3 * 8) + 0.012}
    ];
    _bg3 ctrlCommit 0;
}];

// Settings sub-section — label + edit pairs, rows 8–15 (initially hidden)
// Row layout: MaxAI, DistBlufor, DistOpfor, DistIndep, DistCiv, Interval, MinRadius, CombatRad
private _settingsDefs = [
    ["Max AI:",      9210, 9211],
    ["Dist BLUFOR:", 9212, 9213],
    ["Dist OPFOR:",  9214, 9215],
    ["Dist Indep:",  9216, 9217],
    ["Dist Civ:",    9218, 9219],
    ["Interval(s):", 9222, 9223],
    ["Min Radius:",  9224, 9225],
    ["Combat Rad:",  9227, 9228]
];
private _lW = 0.135;
private _eX = _wx + 0.007 + _lW + 0.004;
private _eW = _w - 0.007 - _lW - 0.004 - 0.007;

{
    _x params ["_lbl", "_lIDC", "_eIDC"];
    private _rowY = _y + _tH + 0.006 + (_rH * (_forEachIndex + 8));

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

// Debug toggle button (row 16, initially hidden)
private _debugBtn = _display ctrlCreate ["RscButton", 9226];
_debugBtn ctrlSetPosition [_wx + 0.007, _y + _tH + 0.006 + (_rH * 16), _w - 0.014, _rH - 0.004];
_debugBtn ctrlSetText (if (AIC_debug) then {"Debug: ON"} else {"Debug: OFF"});
_debugBtn ctrlCommit 0;
_debugBtn ctrlShow false;
_debugBtn ctrlCommit 0;
_debugBtn setVariable ["AIC_debugEnabled", AIC_debug];

_debugBtn ctrlAddEventHandler ["ButtonClick", {
    params ["_btn"];
    private _newVal = !(_btn getVariable ["AIC_debugEnabled", AIC_debug]);
    _btn setVariable ["AIC_debugEnabled", _newVal];
    _btn ctrlSetText (if (_newVal) then {"Debug: ON"} else {"Debug: OFF"});
    _btn ctrlCommit 0;
}];

// Apply button (row 17, initially hidden)
private _applyBtn = _display ctrlCreate ["RscButton", 9220];
_applyBtn ctrlSetPosition [_wx + 0.007, _y + _tH + 0.006 + (_rH * 17), _w - 0.014, _rH - 0.004];
_applyBtn ctrlSetText "Apply";
_applyBtn ctrlCommit 0;
_applyBtn ctrlShow false;
_applyBtn ctrlCommit 0;

_applyBtn ctrlAddEventHandler ["ButtonClick", {
    params ["_btn"];
    private _disp      = ctrlParent _btn;
    private _maxAI     = parseNumber ctrlText (_disp displayCtrl 9211);
    private _distB     = parseNumber ctrlText (_disp displayCtrl 9213);
    private _distO     = parseNumber ctrlText (_disp displayCtrl 9215);
    private _distI     = parseNumber ctrlText (_disp displayCtrl 9217);
    private _distC     = parseNumber ctrlText (_disp displayCtrl 9219);
    private _interval  = parseNumber ctrlText (_disp displayCtrl 9223);
    private _minRad    = parseNumber ctrlText (_disp displayCtrl 9225);
    private _combatRad = parseNumber ctrlText (_disp displayCtrl 9228);
    private _debug     = (_disp displayCtrl 9226) getVariable ["AIC_debugEnabled", AIC_debug];
    [_maxAI, _distB, _distO, _distI, _distC, _interval, _minRad, _combatRad, _debug] remoteExecCall ["AIC_fnc_applySettings", 2];
}];
