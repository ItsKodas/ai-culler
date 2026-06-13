class CfgPatches {
    class aic_main {
        name = "AI Culler";
        author = "koda";
        url = "";
        requiredVersion = 1.98;
        requiredAddons[] = {};
        version = "1.0.0";
        versionStr = "1.0.0";
        versionAr[] = {1, 0, 0};
    };
};

class CfgFunctions {
    class AIC {
        tag = "AIC";
        class Main {
            file = "aic\aic_main\functions";
            class preInit      { preInit  = 1; };
            class postInit     { postInit = 1; };
            class mainLoop         {};
            class enableUnit       {};
            class disableUnit      {};
            class getCullDist      {};
            class broadcastStats   {};
            class toggleProtection {};
            class initZeusHooks    {};
            class createStatusWindow {};
            class updateStatusWindow {};
            class setCullerEnabled {};
            class applySettings    {};
        };
    };
};

// ---------------------------------------------------------------------------
// Zeus placement attribute panel — "Protect from culler" checkbox
//
// curatorInfoType tells Zeus which class defines the placement panel UI for
// units of that type. AIC_CuratorInfo_Man adds a single checkbox (IDC 9300)
// that, when confirmed, sets zeusProtected = true on every placed unit.
//
// !! VERIFY IN CONFIG VIEWER BEFORE SHIPPING !!
// 1. Open CfgVehicles >> CuratorInfo_Tank (or CuratorInfo_Car) in Config Viewer.
//    - Confirm the correct base class name to inherit from (currently inheriting
//      from nothing — add the BI base class if one exists).
//    - Confirm the dialog IDD used in the statement's findDisplay call.
//      Placeholder IDD 312 is the generic Zeus interface; the placement
//      confirmation dialog may have a different IDD.  Check what IDD BI's own
//      crew checkbox uses and replace 312 below.
// 2. Verify x/y/w/h control positions look correct in-game and adjust as needed.
// ---------------------------------------------------------------------------

class CfgVehicles {

    // --- Placement attribute panel definition ---
    class AIC_CuratorInfo_Man {

        // SQF executed when Zeus confirms placement.
        // _this == [placedObjects, curatorObject]
        // !! Replace 312 with the verified placement-dialog IDD !!
        statement = "params ['_objects', '_curator']; private _protect = ctrlChecked ((findDisplay 312) displayCtrl 9300); if (_protect) then { {_x setVariable ['zeusProtected', true, true]} forEach _objects; if (AIC_debug) then { diag_log format ['[AIC] Zeus protected at placement: %1 unit(s)', count _objects]; }; };";

        class controls {
            class AIC_ProtectCheckBox {
                idc         = 9300;           // unique IDC — outside AIC status-window range (9200-9207)
                type        = 0;              // CT_STATIC placeholder; real type comes from RscCheckBox
                style       = 0;
                // !! These inherit from RscCheckBox — if Config Viewer shows a
                //    different base-class name in BI's own curator controls, use that. !!
                x           = 0.05;
                y           = 0.02;
                w           = 0.4;
                h           = 0.04;
                text        = "Protect from culler";
            };
        };
    };

    // --- Patch Man to use our panel ---
    class Man {
        curatorInfoType = "AIC_CuratorInfo_Man";
    };
};

