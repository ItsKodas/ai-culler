params ["_enabled"];
AIC_cullerEnabled = _enabled;
if (AIC_debug) then {
    diag_log format ["[AIC] Culler %1", if (_enabled) then {"enabled"} else {"disabled"}];
};
