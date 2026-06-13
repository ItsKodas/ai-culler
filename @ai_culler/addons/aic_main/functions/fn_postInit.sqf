if (isServer) then {
    if (AIC_debug) then { diag_log "[AIC] Server — starting culler loop"; };
    [] spawn AIC_fnc_mainLoop;
};

if (hasInterface) then {
    [] spawn {
        waitUntil { !isNull player };
        if (AIC_debug) then { diag_log "[AIC] Interface machine — init Zeus hooks"; };
        [] call AIC_fnc_initZeusHooks;
    };
};
