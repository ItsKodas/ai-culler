AIC_clientEnabled     = true;
AIC_clientRadius      = 1500;  // set this to match your server's object view distance
AIC_clientSafeRadius  = 75;
AIC_clientInterval    = 0.3;
AIC_clientHidden      = [];
AIC_clientDebug       = false;

if (!hasInterface) exitWith {};

[] spawn {
    waitUntil { !isNull player };
    sleep 5;
    [] call AIC_fnc_clientLoop;
};

[] call AIC_fnc_clientZeusHooks;
