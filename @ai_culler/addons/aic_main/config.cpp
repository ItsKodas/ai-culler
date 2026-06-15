class CfgPatches {
    class aic_main {
        name = "AI Culler";
        author = "koda";
        url = "";
        units[] = {};
        weapons[] = {};
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
            file = "aic_main\functions";
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
            class setCullerEnabled  {};
            class applySettings     {};
            class updateUnitLabel   {};
        };
    };
};

class CfgCuratorContextActions {
    class AIC_ToggleProtection {
        displayName = "Toggle Culler Protection";
        icon = "";
        priority = 10;
        cursorOver = "";
        condition = "{ alive _x && !isPlayer _x && (_x isKindOf 'CAManBase') } count (_this select 2) > 0";
        statement = "[_this select 2] remoteExec ['AIC_fnc_toggleProtection', 2];";
    };
};

class CfgNotifications {
    class AIC_StateNotification {
        title = "AI Culler";
        iconPicture = "\A3\ui_f\data\map\mapcontrol\taskIcon_ca.paa";
        iconText = "";
        description = "%1";
        color[] = {1, 0.65, 0, 1};
        colorIconPicture[] = {1, 0.65, 0, 1};
        duration = 6;
        priority = 5;
        difficulty[] = {};
    };
};
