// AIC_fnc_renderFpsGraph — redraws the server FPS sparkline from AIC_fpsHistory.
// Called by the 1-second FPS refresh loop and immediately on panel open.
// Exits silently when the Zeus display or graph panel is not visible.
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

// Downsample to _maxCols evenly-spaced points so the sparkline always fills
// the panel width regardless of how much history has been collected.
private _maxCols = 55;
private _displayData = [];
if (_n <= _maxCols) then {
    _displayData = _history;
} else {
    for "_i" from 0 to (_maxCols - 1) do {
        _displayData pushBack (_history select (floor (_i * _n / _maxCols)));
    };
};

// ASCII height chars ordered low -> high (avoids multi-byte UTF-8 which
// can confuse Arma's SQF preprocessor when read as Windows-1252).
private _maxFPS    = 60;
private _heightChars = ["_", ".", "-", "~", "+", "s", "I", "#"];
private _text      = "";
{
    private _fps   = _x min _maxFPS max 0;
    private _idx   = floor (_fps / _maxFPS * 7) min 7;
    private _char  = _heightChars select _idx;
    private _color = if (_fps >= 40) then { "#44ff88" } else {
                     if (_fps >= 25) then { "#ffcc22" } else { "#ff4444" } };
    _text = _text + format ["<t size='2' color='%1'>%2</t>", _color, _char];
} forEach _displayData;

_graphCtrl ctrlSetStructuredText parseText _text;
_graphCtrl ctrlCommit 0;
