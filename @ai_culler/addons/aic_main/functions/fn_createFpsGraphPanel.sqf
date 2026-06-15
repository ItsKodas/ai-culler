// AIC_fnc_createFpsGraphPanel — builds the floating server FPS graph panel.
// Positioned at the bottom of the screen beneath the main AIC panel (same X/W).
// Initially hidden; toggled by the FPS Graph button (IDC 9250) in the status window.
params ["_display"];
if (isNull _display) exitWith {};

{ private _c = _display displayCtrl _x; if (!isNull _c) then { ctrlDelete _c }; }
    forEach [9251,9252,9253,9254];

private _gx    = safeZoneX + 0.35;
private _gw    = 0.38;
private _tH    = 0.036;
private _gH    = 0.066;   // sparkline area height (~2 row-heights)
private _legH  = 0.022;
private _pad   = 0.006;
private _total = _tH + _pad + _gH + _pad + _legH + _pad;
private _gy    = safeZoneY + safeZoneH - _total - 0.015;

// Background
private _bg = _display ctrlCreate ["RscText", 9251];
_bg ctrlSetPosition [_gx, _gy, _gw, _total];
_bg ctrlSetBackgroundColor [0, 0, 0, 0.78];
_bg ctrlShow false;
_bg ctrlCommit 0;

// Title bar
private _titleCtrl = _display ctrlCreate ["RscText", 9252];
_titleCtrl ctrlSetPosition [_gx + 0.005, _gy + 0.003, _gw - 0.01, _tH - 0.006];
_titleCtrl ctrlSetText "Server FPS - Last 5 min";
_titleCtrl ctrlSetBackgroundColor [0.12, 0.12, 0.12, 1];
_titleCtrl ctrlShow false;
_titleCtrl ctrlCommit 0;

// Sparkline — RscStructuredText for per-character colour coding
private _graphCtrl = _display ctrlCreate ["RscStructuredText", 9253];
_graphCtrl ctrlSetPosition [_gx + 0.005, _gy + _tH + _pad, _gw - 0.01, _gH];
_graphCtrl ctrlSetStructuredText parseText "<t color='#888888'>Waiting for data...</t>";
_graphCtrl ctrlShow false;
_graphCtrl ctrlCommit 0;

// Legend: colour key left, time axis right
private _legendCtrl = _display ctrlCreate ["RscText", 9254];
_legendCtrl ctrlSetPosition [_gx + 0.005, _gy + _tH + _pad + _gH + _pad, _gw - 0.01, _legH];
_legendCtrl ctrlSetText "green >=40fps   yellow >=25fps   red <25fps              <- older   now ->";
_legendCtrl ctrlSetTextColor [0.55, 0.55, 0.55, 1];
_legendCtrl ctrlShow false;
_legendCtrl ctrlCommit 0;
