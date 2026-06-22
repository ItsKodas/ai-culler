params ["_display"];

if (isNull _display) exitWith {};

// Remove existing controls (idempotent)
{ ctrlDelete (_display displayCtrl _x); } forEach [9200,9201,9202,9203,9204,9205,9206,9207,9208,9209,9210,9211,9212,9213,9214,9215,9216,9217,9218,9219,9220,9221,9222,9223,9224,9225,9226,9227,9228,9229,9230,9231];

private _wx    = safeZoneX + 0.35;
private _y     = safeZoneY + 0.07;
private _w     = 0.38;
private _rH    = 0.033;
private _tH    = 0.036;
private _colW  = 0.175;
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
            forEach [9203,9204,9205,9206,9207,9221,9229,9230,9231,9208,9209,9250,9210,9211,9212,9213,9214,9215,9216,9217,9218,9219,9222,9223,9224,9225,9227,9228,9226,9220,9251,9252,9253,9254];
    } else {
        { (_disp displayCtrl _x) ctrlShow true; (_disp displayCtrl _x) ctrlCommit 0; }
            forEach [9203,9204,9205,9206,9207,9221,9229,9230,9231,9208,9209,9250];
        if ((_disp displayCtrl 9250) getVariable ["AIC_graphOpen", false]) then {
            { (_disp displayCtrl _x) ctrlShow true; (_disp displayCtrl _x) ctrlCommit 0; }
                forEach [9251,9252,9253,9254];
        };
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

    if (AIC_showNotifications) then {
        private _msg = format ["AI Culler %1 by %2", if (_newState) then {"Enabled"} else {"Disabled"}, name player];
        ["AIC_StateNotification", [_msg]] remoteExec ["BIS_fnc_showNotification", 0];
    };

    _btn ctrlSetText (if (_newState) then {"Disable Culler"} else {"Enable Culler"});
    _btn ctrlCommit 0;
}];

// Row 7: Settings (left half) + FPS Graph (right half)
private _halfBtnW = (_w - 0.018) / 2;

// Settings toggle button (row 7, left half)
private _settingsToggle = _display ctrlCreate ["RscButton", 9209];
_settingsToggle ctrlSetPosition [_wx + 0.007, _y + _tH + 0.006 + (_rH * 7), _halfBtnW, _rH - 0.004];
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

// FPS Graph toggle button (row 7, right half)
private _graphToggle = _display ctrlCreate ["RscButton", 9250];
_graphToggle ctrlSetPosition [_wx + 0.007 + _halfBtnW + 0.004, _y + _tH + 0.006 + (_rH * 7), _halfBtnW, _rH - 0.004];
_graphToggle ctrlSetText "FPS Graph";
_graphToggle ctrlCommit 0;
_graphToggle setVariable ["AIC_graphOpen", false];

_graphToggle ctrlAddEventHandler ["ButtonClick", {
    params ["_btn"];
    private _disp = ctrlParent _btn;
    private _open = !(_btn getVariable ["AIC_graphOpen", false]);
    _btn setVariable ["AIC_graphOpen", _open];
    { private _c = _disp displayCtrl _x; if (!isNull _c) then { _c ctrlShow _open; _c ctrlCommit 0; }; }
        forEach [9251,9252,9253,9254];
    if (_open) then { [] call AIC_fnc_renderFpsGraph };
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
    _edtCtrl ctrlAddEventHandler ["KeyDown", {
        params ["_ctrl", "_key"];
        if (_key == 14) exitWith { true };
        false
    }];
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

// DIK_BACK = 14, CT_EDIT = 2, CT_XLISTBOX = 8, CT_LISTNBOX = 96,
// CT_CONTROLS_GROUP = 15.
// When backspace is pressed with a text-input control focused, consume
// the key so Zeus's HUD toggle does not fire. Zeus's native text boxes
// sit inside controls groups (type 15), so check one level of children.
// When backspace falls through (no text input active), Zeus will toggle
// its HUD — spawn a brief delayed update to mirror that in our panel.
_display displayAddEventHandler ["KeyDown", {
    params ["_display", "_key"];
    if (_key != 14) exitWith { false };
    // AIC edit controls handle backspace via their own KeyDown EH. This path
    // covers vanilla Zeus text boxes (direct CT_EDIT or inside a CT_CONTROLS_GROUP).
    private _focused = focusedCtrl _display;
    if (isNull _focused) exitWith { false };
    private _type = ctrlType _focused;
    if (_type in [2, 8, 96]) exitWith { true };
    if (_type == 15) exitWith {
        (allControls _focused) findIf { (ctrlType _x) in [2, 8, 96] } != -1
    };
    // Backspace reaches Zeus and toggles the HUD. Wait 0.1s for Arma to set
    // RscDisplayCurator_screenshotMode (same technique used by other Zeus mods),
    // then read it directly rather than guessing from our own panel state.
    [_display] spawn {
        params ["_disp"];
        uiSleep 0.1;
        if (uiNamespace getVariable ["RscDisplayCurator_screenshotMode", false]) then {
            { private _c = _disp displayCtrl _x; if (!isNull _c) then { _c ctrlShow false; _c ctrlCommit 0; }; }
                forEach [9200,9201,9202,9203,9204,9205,9206,9207,9221,9229,9230,9231,9208,9209,9250,9210,9211,9212,9213,9214,9215,9216,9217,9218,9219,9222,9223,9224,9225,9227,9228,9226,9220,9251,9252,9253,9254];
        } else {
            private _collapsed    = (_disp displayCtrl 9202) getVariable ["AIC_collapsed", false];
            private _settingsOpen = (_disp displayCtrl 9209) getVariable ["AIC_settingsOpen", false];
            private _graphOpen    = (_disp displayCtrl 9250) getVariable ["AIC_graphOpen", false];
            { private _c = _disp displayCtrl _x; if (!isNull _c) then { _c ctrlShow true; _c ctrlCommit 0; }; }
                forEach [9200,9201,9202];
            if (!_collapsed) then {
                { private _c = _disp displayCtrl _x; if (!isNull _c) then { _c ctrlShow true; _c ctrlCommit 0; }; }
                    forEach [9203,9204,9205,9206,9207,9221,9229,9230,9231,9208,9209,9250];
                if (_graphOpen) then {
                    { private _c = _disp displayCtrl _x; if (!isNull _c) then { _c ctrlShow true; _c ctrlCommit 0; }; }
                        forEach [9251,9252,9253,9254];
                };
                if (_settingsOpen) then {
                    { private _c = _disp displayCtrl _x; if (!isNull _c) then { _c ctrlShow true; _c ctrlCommit 0; }; }
                        forEach [9210,9211,9212,9213,9214,9215,9216,9217,9218,9219,9222,9223,9224,9225,9227,9228,9226,9220];
                };
            };
        };
    };
    false
}];
