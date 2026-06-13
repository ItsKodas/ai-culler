if !(isServer) exitWith {};
params ["_maxAI", "_distBlufor", "_distOpfor", "_distIndep", "_distCiv", "_interval", "_minRadius", "_combatRadius", "_debug"];

AIC_maxActiveAI     = _maxAI;
AIC_distBlufor      = _distBlufor;
AIC_distOpfor       = _distOpfor;
AIC_distIndependent = _distIndep;
AIC_distCivilian    = _distCiv;
AIC_checkInterval   = _interval;
AIC_minActiveRadius = _minRadius;
AIC_combatRadius    = _combatRadius;
AIC_debug           = _debug;

publicVariable "AIC_maxActiveAI";
publicVariable "AIC_distBlufor";
publicVariable "AIC_distOpfor";
publicVariable "AIC_distIndependent";
publicVariable "AIC_distCivilian";
publicVariable "AIC_checkInterval";
publicVariable "AIC_minActiveRadius";
publicVariable "AIC_combatRadius";
publicVariable "AIC_debug";

if (AIC_debug) then {
    diag_log format ["[AIC] Settings applied — maxAI:%1 distB:%2 distO:%3 distI:%4 distC:%5 interval:%6 minRad:%7 combatRad:%8 debug:%9",
        _maxAI, _distBlufor, _distOpfor, _distIndep, _distCiv, _interval, _minRadius, _combatRadius, _debug];
};
