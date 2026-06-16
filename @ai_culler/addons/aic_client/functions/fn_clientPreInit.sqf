if (!hasInterface) exitWith {};

// Only apply hard-coded defaults if CBA hasn't already populated these from the saved profile
if (isNil "AIC_clientEnabled")    then { AIC_clientEnabled    = true  };
if (isNil "AIC_clientSafeRadius") then { AIC_clientSafeRadius = 75    };
if (isNil "AIC_clientDebug")      then { AIC_clientDebug      = false };
AIC_clientHidden     = [];

// --- Adaptive cadence (FPS -> interval ramp) ---
AIC_clientIntervalMin = 0.2;   // fastest cadence at/above FpsTarget
AIC_clientIntervalMax = 1.0;   // slowest cadence at/below FpsFloor
AIC_clientFpsFloor    = 15;    // at/below: widest interval + budget throttle
AIC_clientFpsTarget   = 45;    // at/above: tightest interval

// --- Pool-size budget (target ~50-100 AI high end) ---
AIC_clientSweepTicks = 3;      // clear any sweep in ~this many ticks (primary knob)
AIC_clientBudgetMin  = 10;     // slice floor when FPS is collapsing
AIC_clientBudgetMax  = 60;     // spike-guard; handles ~200 AI in ~4 ticks at 0.2s cadence

// postInit: player is already initialised — no spawn or sleep needed
private _hasAce = isClass (configFile >> "CfgPatches" >> "ace_main");

if (_hasAce) then {
    private _vd = missionNamespace getVariable ["ace_viewdistance_viewDistanceOnFoot", 0];
    if (_vd == 0) then { _vd = getVideoOptions get "overallVisibility" };
    if (isNil "_vd" || { _vd <= 0 }) then { _vd = viewDistance };
    AIC_clientRadius = _vd;
} else {
    AIC_clientRadius = viewDistance;
};

[] call AIC_fnc_clientLoop;

// Slow poll: track mid-mission view distance changes without touching the hot path
[_hasAce] spawn {
    params ["_hasAce"];
    while {true} do {
        uiSleep 30;
        if (_hasAce) then {
            private _vd = missionNamespace getVariable ["ace_viewdistance_viewDistanceOnFoot", 0];
            if (_vd == 0) then { _vd = getVideoOptions get "overallVisibility" };
            if (isNil "_vd" || { _vd <= 0 }) then { _vd = viewDistance };
            AIC_clientRadius = _vd;
        } else {
            AIC_clientRadius = viewDistance;
        };
    };
};
