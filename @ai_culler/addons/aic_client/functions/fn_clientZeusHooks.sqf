if (!hasInterface) exitWith {};

[] spawn {
    while {true} do {
        waitUntil { !isNull (findDisplay 312) };
        [findDisplay 312] call AIC_fnc_createClientPanel;

        // Backspace mirrors the main AIC panel toggle
        (findDisplay 312) displayAddEventHandler ["KeyDown", {
            params ["_disp", "_key"];
            if (_key == 14) then {
                private _bg = _disp displayCtrl 9300;
                if (!isNull _bg) then {
                    private _hidden = _bg getVariable ["AIC_hidden", false];
                    { private _c = _disp displayCtrl _x; if (!isNull _c) then { _c ctrlShow _hidden; _c ctrlCommit 0; }; }
                        forEach [9300,9301,9302,9303,9304,9305,9306,9307,9308,9309,9310,9311];
                    _bg setVariable ["AIC_hidden", !_hidden];
                };
            };
            false
        }];

        waitUntil { isNull (findDisplay 312) };
    };
};
