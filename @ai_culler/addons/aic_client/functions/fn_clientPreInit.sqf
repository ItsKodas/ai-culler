AIC_clientEnabled    = true;
AIC_clientRadius     = 600;
AIC_clientSafeRadius = 75;
AIC_clientInterval   = 0.3;
AIC_clientHidden     = [];

if (!hasInterface) exitWith {};

[] spawn {
    waitUntil { !isNull player };
    sleep 5;
    [] call AIC_fnc_clientLoop;
};
