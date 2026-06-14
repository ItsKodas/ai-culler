params ["_display"];

if (isNull _display) exitWith {};

// Remove existing controls (idempotent)
{ ctrlDelete (_display displayCtrl _x); } forEach [9300,9301,9302,9303,9304,9305,9306,9307,9308,9309,9310,9311];

private _wx  = safeZoneX + 0.687;  // right of main AIC panel (0.35 + 0.33 + 0.007 gap)
private _y   = safeZoneY + 0.07;
private _w   = 0.255;
private _rH  = 0.033;
private _tH  = 0.036;
private _lW  = 0.135;
private _eX  = _wx + 0.007 + _lW + 0.004;
private _eW  = _w - 0.007 - _lW - 0.004 - 0.007;

// Background — 6 rows
private _bg = _display ctrlCreate ["RscText", 9300];
_bg ctrlSetPosition [_wx, _y, _w, _tH + (_rH * 6) + 0.012];
_bg ctrlSetBackgroundColor [0, 0, 0, 0.78];
_bg ctrlCommit 0;

// Title
private _title = _display ctrlCreate ["RscText", 9301];
_title ctrlSetPosition [_wx + 0.005, _y + 0.003, _w - 0.045, _tH - 0.006];
_title ctrlSetText "Client Renderer";
_title ctrlSetBackgroundColor [0.12, 0.12, 0.12, 1];
_title ctrlCommit 0;

// Collapse/expand button
private _collapseBtn = _display ctrlCreate ["RscButton", 9302];
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

    { (_disp displayCtrl _x) ctrlShow (!_collapse); (_disp displayCtrl _x) ctrlCommit 0; }
        forEach [9303,9304,9305,9306,9307,9308,9309,9310,9311];

    private _bg2  = _disp displayCtrl 9300;
    private _pos  = ctrlPosition _bg2;
    private _tH2  = 0.036;
    private _rH2  = 0.033;
    _bg2 ctrlSetPosition [
        _pos select 0, _pos select 1, _pos select 2,
        if (_collapse) then {_tH2 + 0.004} else {_tH2 + (_rH2 * 6) + 0.012}
    ];
    _bg2 ctrlCommit 0;
}];

// Row 0: enable/disable toggle
private _enableBtn = _display ctrlCreate ["RscButton", 9303];
_enableBtn ctrlSetPosition [_wx + 0.007, _y + _tH + 0.006 + (_rH * 0), _w - 0.014, _rH - 0.004];
_enableBtn ctrlSetText (if (AIC_clientEnabled) then {"Client Renderer: ON"} else {"Client Renderer: OFF"});
_enableBtn ctrlCommit 0;
_enableBtn setVariable ["AIC_clientOn", AIC_clientEnabled];

_enableBtn ctrlAddEventHandler ["ButtonClick", {
    params ["_btn"];
    private _newVal = !(_btn getVariable ["AIC_clientOn", true]);
    _btn setVariable ["AIC_clientOn", _newVal];
    _btn ctrlSetText (if (_newVal) then {"Client Renderer: ON"} else {"Client Renderer: OFF"});
    _btn ctrlCommit 0;
}];

// Rows 1–3: label + edit pairs
private _settingsDefs = [
    ["Radius:",      9304, 9305, str AIC_clientRadius],
    ["Safe Radius:", 9306, 9307, str AIC_clientSafeRadius],
    ["Interval(s):", 9308, 9309, str AIC_clientInterval]
];

{
    _x params ["_lbl", "_lIDC", "_eIDC", "_val"];
    private _rowY = _y + _tH + 0.006 + (_rH * (_forEachIndex + 1));

    private _lblCtrl = _display ctrlCreate ["RscText", _lIDC];
    _lblCtrl ctrlSetPosition [_wx + 0.007, _rowY, _lW, _rH - 0.004];
    _lblCtrl ctrlSetText _lbl;
    _lblCtrl ctrlCommit 0;

    private _edtCtrl = _display ctrlCreate ["RscEdit", _eIDC];
    _edtCtrl ctrlSetPosition [_eX, _rowY, _eW, _rH - 0.004];
    _edtCtrl ctrlSetText _val;
    _edtCtrl ctrlCommit 0;
} forEach _settingsDefs;

// Row 4: debug HUD toggle
private _debugBtn = _display ctrlCreate ["RscButton", 9311];
_debugBtn ctrlSetPosition [_wx + 0.007, _y + _tH + 0.006 + (_rH * 4), _w - 0.014, _rH - 0.004];
_debugBtn ctrlSetText (if (AIC_clientDebug) then {"Debug HUD: ON"} else {"Debug HUD: OFF"});
_debugBtn ctrlCommit 0;
_debugBtn setVariable ["AIC_debugOn", AIC_clientDebug];

_debugBtn ctrlAddEventHandler ["ButtonClick", {
    params ["_btn"];
    private _newVal = !(_btn getVariable ["AIC_debugOn", false]);
    _btn setVariable ["AIC_debugOn", _newVal];
    _btn ctrlSetText (if (_newVal) then {"Debug HUD: ON"} else {"Debug HUD: OFF"});
    _btn ctrlCommit 0;
}];

// Row 5: Apply — sets globals and publicVariables to all clients
private _applyBtn = _display ctrlCreate ["RscButton", 9310];
_applyBtn ctrlSetPosition [_wx + 0.007, _y + _tH + 0.006 + (_rH * 5), _w - 0.014, _rH - 0.004];
_applyBtn ctrlSetText "Apply";
_applyBtn ctrlCommit 0;

_applyBtn ctrlAddEventHandler ["ButtonClick", {
    params ["_btn"];
    private _disp = ctrlParent _btn;

    AIC_clientEnabled    = (_disp displayCtrl 9303) getVariable ["AIC_clientOn", true];
    AIC_clientRadius     = parseNumber ctrlText (_disp displayCtrl 9305);
    AIC_clientSafeRadius = parseNumber ctrlText (_disp displayCtrl 9307);
    AIC_clientInterval   = parseNumber ctrlText (_disp displayCtrl 9309);
    AIC_clientDebug      = (_disp displayCtrl 9311) getVariable ["AIC_debugOn", false];

    publicVariable "AIC_clientEnabled";
    publicVariable "AIC_clientRadius";
    publicVariable "AIC_clientSafeRadius";
    publicVariable "AIC_clientInterval";
    publicVariable "AIC_clientDebug";
}];
