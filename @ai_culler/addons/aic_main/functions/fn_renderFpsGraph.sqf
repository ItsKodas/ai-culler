// AIC_fnc_renderFpsGraph — redraws the server FPS bar chart from AIC_fpsHistory.
// Y-axis = FPS level (auto-scaled), X-axis = time (left=older, right=newer).
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

// Compute stats from current history
private _sum = 0;
private _maxFPS = 0;
private _minFPS = 9999;
{
    _sum = _sum + _x;
    if (_x > _maxFPS) then { _maxFPS = _x };
    if (_x < _minFPS) then { _minFPS = _x };
} forEach _history;
private _avgFPS = round (_sum / _n);

// Update title bar with live average, min, max
private _titleCtrl = _display displayCtrl 9252;
if (!isNull _titleCtrl) then {
    _titleCtrl ctrlSetText format ["Server FPS   avg: %1   min: %2   max: %3", _avgFPS, _minFPS, _maxFPS];
    _titleCtrl ctrlCommit 0;
};

// Stable Y-axis: tracked globals only ever expand outward so the scale never
// jumps when old samples drop off the ring buffer end.
if (isNil "AIC_fpsYMin") then { AIC_fpsYMin = _minFPS };
if (isNil "AIC_fpsYMax") then { AIC_fpsYMax = _maxFPS };
AIC_fpsYMin = _minFPS min AIC_fpsYMin;
AIC_fpsYMax = _maxFPS max AIC_fpsYMax;

private _topRow = (ceil  (AIC_fpsYMax / 10)) * 10;
private _botRow = (floor (AIC_fpsYMin / 10)) * 10;
if (_topRow == _botRow) then { _topRow = _botRow + 10 };

// Ensure at least 4 rows visible
if ((_topRow - _botRow) < 40) then {
    private _mid = (floor ((_topRow + _botRow) / 20)) * 10;
    _topRow = _mid + 20;
    _botRow = _mid - 20;
    if (_botRow < 0) then { _botRow = 0 };
    if ((_topRow - _botRow) < 40) then { _topRow = _botRow + 40 };
};

// Cap at 8 rows max; trim from the bottom
if ((_topRow - _botRow) > 80) then { _botRow = _topRow - 80 };

// Array length is capped at 88 by the accumulation loop, so _history IS the
// display data — no downsampling or windowing needed.

// Build bar chart: one row per FPS level, O where fps >= that level
private _text = "";
private _row = _topRow;
while { _row >= _botRow } do {
    // Right-align label in 3 chars, e.g. " 50" or "100"
    private _lbl = str _row;
    if ((count _lbl) < 3) then { _lbl = " " + _lbl };
    if ((count _lbl) < 3) then { _lbl = " " + _lbl };

    // Build the dot string for this row, right-aligned so data fills right-to-left.
    // Pad the left side with spaces until the array reaches full width (88 cols).
    private _rowStr = "";
    for "_p" from 1 to (88 - _n) do { _rowStr = _rowStr + " "; };
    { _rowStr = _rowStr + (if (_x >= _row) then { "O" } else { " " }); } forEach _history;

    _text = _text + format [
        "<t font='LucidaConsoleB' size='0.55' color='#666666'>%1|</t><t font='LucidaConsoleB' size='0.55' color='#44ff88'>%2</t><br/>",
        _lbl,
        _rowStr
    ];

    _row = _row - 10;
};

_graphCtrl ctrlSetStructuredText parseText _text;
_graphCtrl ctrlCommit 0;
