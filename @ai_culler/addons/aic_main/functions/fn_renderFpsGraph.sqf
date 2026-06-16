// AIC_fnc_renderFpsGraph — redraws the server FPS sparkline from AIC_fpsHistory.
// Single-row ASCII sparkline: 8 height levels scaled to session peak FPS.
// Called by the 1-second refresh loop and on panel open.
private _display = findDisplay 312;
if (isNull _display) exitWith {};
private _graphCtrl = _display displayCtrl 9253;
if (isNull _graphCtrl || { !ctrlShown _graphCtrl }) exitWith {};

if (isNil "AIC_fpsHistory") then { AIC_fpsHistory = [] };
private _history = AIC_fpsHistory;
private _n = count _history;

if (_n == 0) exitWith {
    _graphCtrl ctrlSetStructuredText parseText "<t color='#888888'>Waiting for data...</t>";
    _graphCtrl ctrlCommit 0;
};

// Stats
private _sum = 0;
private _maxFPS = 0;
private _minFPS = 9999;
{
    _sum = _sum + _x;
    if (_x > _maxFPS) then { _maxFPS = _x };
    if (_x < _minFPS) then { _minFPS = _x };
} forEach _history;
private _avgFPS = round (_sum / _n);
private _nowFPS = _history select (_n - 1);

// Update title bar
private _titleCtrl = _display displayCtrl 9252;
if (!isNull _titleCtrl) then {
    _titleCtrl ctrlSetText format ["Server FPS  now: %1   avg: %2   min: %3   max: %4", _nowFPS, _avgFPS, _minFPS, _maxFPS];
    _titleCtrl ctrlCommit 0;
};

// Stable session peak: only ever grows so sparkline height stays consistent
if (isNil "AIC_fpsYMax") then { AIC_fpsYMax = _maxFPS };
AIC_fpsYMax = _maxFPS max AIC_fpsYMax;
private _topScale = (ceil (AIC_fpsYMax / 10)) * 10;
if (_topScale < 1) then { _topScale = 1 };

// 8-level ASCII height chars: low -> high
private _chars = ["_", ".", "-", "~", "+", "s", "I", "#"];

// Build sparkline as a single monospace string — one <t> tag avoids parseText failures
// from large per-character tag strings, and sidesteps any size/clip issues.
private _line = "";
for "_p" from 1 to (88 - _n) do { _line = _line + " "; };
{
    private _idx = (floor (_x / _topScale * 7)) min 7 max 0;
    _line = _line + (_chars select _idx);
} forEach _history;

_graphCtrl ctrlSetStructuredText parseText format [
    "<t font='LucidaConsoleB' size='0.55' color='#44ff88'>%1</t>", _line
];
_graphCtrl ctrlCommit 0;
