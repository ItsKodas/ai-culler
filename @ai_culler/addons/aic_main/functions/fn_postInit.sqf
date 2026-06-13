if (isServer) then {
    if (AIC_debug) then { diag_log "[AIC] Server — starting culler loop"; };
    [] spawn AIC_fnc_mainLoop;
};

if (hasInterface) then {
    [] spawn {
        waitUntil { !isNull player };

        AIC_zeusHooksInit = false;

        if (!isNull (getAssignedCuratorLogic player)) then {
            if (AIC_debug) then { diag_log "[AIC] Curator machine — init Zeus hooks"; };
            AIC_zeusHooksInit = true;
            [] call AIC_fnc_initZeusHooks;
        };

        player addEventHandler ["CuratorAssigned", {
            if (!AIC_zeusHooksInit) then {
                if (AIC_debug) then { diag_log "[AIC] Curator assigned mid-mission — init Zeus hooks"; };
                AIC_zeusHooksInit = true;
                [] call AIC_fnc_initZeusHooks;
            };
        }];
    };
};
