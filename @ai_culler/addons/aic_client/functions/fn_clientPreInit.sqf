AIC_clientEnabled    = true;
AIC_clientSafeRadius = 75;
AIC_clientInterval   = 0.3;
AIC_clientHidden     = [];
AIC_clientDebug      = false;

if (!hasInterface) exitWith {};

[] spawn {
    waitUntil { !isNull player };
    sleep 5;

    if (isClass (configFile >> "CfgPatches" >> "ace_main")) then {
        private _readVD = {
            private _vd = missionNamespace getVariable ["ace_viewdistance_viewDistanceOnFoot", 0];
            if (_vd == 0) then { _vd = getVideoOptions get "overallVisibility" };
            _vd
        };
        AIC_clientRadius = call _readVD;
        [] call AIC_fnc_clientLoop;
        // Keep culling radius in sync if the player changes ACE view distance mid-mission
        while {true} do {
            sleep 5;
            AIC_clientRadius = call _readVD;
        };
    } else {
        AIC_clientRadius = 2000;
        [] call AIC_fnc_clientLoop;
    };
};
[] call AIC_fnc_clientZeusHooks;
