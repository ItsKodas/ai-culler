if !(isServer) exitWith {};
params ["_maxAI", "_distOpfor", "_distIndep", "_distCiv", "_interval"];

AIC_maxActiveAI     = _maxAI;
AIC_distOpfor       = _distOpfor;
AIC_distIndependent = _distIndep;
AIC_distCivilian    = _distCiv;
AIC_checkInterval   = _interval;

publicVariable "AIC_maxActiveAI";
publicVariable "AIC_distOpfor";
publicVariable "AIC_distIndependent";
publicVariable "AIC_distCivilian";
publicVariable "AIC_checkInterval";

if (AIC_debug) then {
    diag_log format ["[AIC] Settings applied — maxAI:%1 distO:%2 distI:%3 distC:%4 interval:%5",
        _maxAI, _distOpfor, _distIndep, _distCiv, _interval];
};
