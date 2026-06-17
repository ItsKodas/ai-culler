// Register CBA settings after CBA XEH PreInit has finished so they survive
// CBA's internal registry reset at the start of its XEH phase.
diag_log "[AIC] postInit: registering settings";
[] call AIC_fnc_registerSettings;
diag_log "[AIC] postInit: settings registered";

if (isServer) then {
    if (AIC_debug) then { diag_log "[AIC] Server — starting culler loop"; };
    [] spawn AIC_fnc_mainLoop;

    // Seed with current FPS before mission load so the initial display is close
    // to the server's configured cap rather than an arbitrary placeholder.
    AIC_serverFPS = round diag_fps;

    // Keep updating every second, independent of the culler tick, so the
    // reading is not biased by the culler's own processing load.
    // Send only to active curator clients rather than broadcasting to everyone.
    [] spawn {
        while {true} do {
            sleep 1;
            AIC_serverFPS = round diag_fps;
            {
                private _player = getAssignedCuratorUnit _x;
                if (!isNull _player) then { (owner _player) publicVariableClient "AIC_serverFPS" };
            } forEach allCurators;
        };
    };

    [] spawn AIC_fnc_waypointMonitor;
};

// postInit: player is already initialised on interface machines — no spawn or waitUntil needed
if (hasInterface) then {
    if (AIC_debug) then { diag_log "[AIC] Interface machine — init Zeus hooks"; };
    [] call AIC_fnc_initZeusHooks;
};
