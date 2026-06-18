params ["_activeCount", "_losCount", "_noLosCount", "_outOfRangeCount", "_protectedCount", "_culledCount", "_overrideCount", "_totalAI", "_serverFPS"];

private _display = findDisplay 312;
if (isNull _display) exitWith {};

private _clientFPS = round diag_fps;

private _texts = [
    format ["Active: %1/%2", _activeCount, AIC_maxActiveAI],
    format ["LOS: %1",         _losCount],
    format ["No-LOS: %1",      _noLosCount],
    format ["Culled: %1",      _culledCount],
    format ["Protected: %1",   _protectedCount],
    format ["Override: %1",    _overrideCount],
    format ["Total AI: %1",    _totalAI],
    format ["Srv FPS: %1",     _serverFPS],
    format ["Clt FPS: %1",     _clientFPS]
];

{
    private _ctrl = _display displayCtrl ([9203,9204,9205,9206,9207,9221,9229,9230,9231] select _forEachIndex);
    if (!isNull _ctrl) then {
        _ctrl ctrlSetText _x;
        _ctrl ctrlCommit 0;
    };
} forEach _texts;

// Color code the Active count relative to the cap
private _ratio = if (AIC_maxActiveAI > 0) then { _activeCount / AIC_maxActiveAI } else { 0 };
private _activeCtrl = _display displayCtrl 9203;

if (_ratio > 2) then {
    // >200% cap — flash red
    if (isNil "AIC_zeusFlashPFH") then {
        AIC_zeusFlashPFH = [{
            private _d = findDisplay 312;
            if (isNull _d) exitWith {
                [AIC_zeusFlashPFH] call CBA_fnc_removePerFrameHandler;
                AIC_zeusFlashPFH = nil;
            };
            private _c = _d displayCtrl 9203;
            if (isNull _c) exitWith {};
            private _on = (floor (diag_tickTime * 2)) % 2 == 0;
            _c ctrlSetTextColor (if (_on) then { [1, 0, 0, 1] } else { [1, 1, 1, 0.2] });
            _c ctrlCommit 0;
        }, 0, []] call CBA_fnc_addPerFrameHandler;
    };
} else {
    // Below flash threshold — stop PFH and apply static color
    if (!isNil "AIC_zeusFlashPFH") then {
        [AIC_zeusFlashPFH] call CBA_fnc_removePerFrameHandler;
        AIC_zeusFlashPFH = nil;
    };
    if (!isNull _activeCtrl) then {
        private _color = if (_ratio < 1) then {
            [0.3, 1, 0.3, 1]       // green: below cap
        } else {
            if (_ratio == 1) then {
                [1, 1, 0, 1]        // yellow: at cap
            } else {
                [1, 0.5, 0, 1]      // orange: over cap, under 200%
            };
        };
        _activeCtrl ctrlSetTextColor _color;
        _activeCtrl ctrlCommit 0;
    };
};

// Keep toggle button label in sync with server state
private _toggleBtn = _display displayCtrl 9208;
if (!isNull _toggleBtn) then {
    _toggleBtn ctrlSetText (if (AIC_cullerEnabled) then {"Disable Culler"} else {"Enable Culler"});
    _toggleBtn ctrlCommit 0;
};
