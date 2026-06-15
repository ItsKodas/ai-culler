if (!hasInterface) exitWith {};

AIC_clientEnabled    = true;
AIC_clientSafeRadius = 75;
AIC_clientDebug      = false;
AIC_clientHidden     = [];

// --- Adaptive cadence (FPS -> interval ramp) ---
AIC_clientIntervalMin = 0.2;   // fastest cadence at/above FpsTarget
AIC_clientIntervalMax = 1.0;   // slowest cadence at/below FpsFloor
AIC_clientFpsFloor    = 15;    // at/below: widest interval + budget throttle
AIC_clientFpsTarget   = 45;    // at/above: tightest interval

// --- Pool-size budget (target ~50-100 AI high end) ---
AIC_clientSweepTicks = 4;      // clear any sweep in ~this many ticks (primary knob)
AIC_clientBudgetMin  = 10;     // slice floor when FPS is collapsing
AIC_clientBudgetMax  = 40;     // snug spike-guard above the 100-AI target

// postInit: player is already initialised — no spawn or sleep needed
private _hasAce = isClass (configFile >> "CfgPatches" >> "ace_main");

if (_hasAce) then {
    private _vd = missionNamespace getVariable ["ace_viewdistance_viewDistanceOnFoot", 0];
    if (_vd == 0) then { _vd = getVideoOptions get "overallVisibility" };
    // guard against nil (key missing from HashMap) or nonsense values
    if (isNil "_vd" || { _vd <= 0 }) then { _vd = 2000 };
    AIC_clientRadius = _vd;
} else {
    AIC_clientRadius = 2000;
};

[] call AIC_fnc_clientLoop;
[] call AIC_fnc_clientZeusHooks;

// Slow poll: track mid-mission ACE VD changes without touching the hot path
if (_hasAce) then {
    [] spawn {
        while {true} do {
            uiSleep 30;
            private _vd = missionNamespace getVariable ["ace_viewdistance_viewDistanceOnFoot", 0];
            if (_vd == 0) then { _vd = getVideoOptions get "overallVisibility" };
            if (isNil "_vd" || { _vd <= 0 }) then { _vd = 2000 };
            AIC_clientRadius = _vd;
        };
    };
};
