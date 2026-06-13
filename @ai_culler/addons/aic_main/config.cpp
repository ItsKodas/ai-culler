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
            class setCullerEnabled {};
            class applySettings    {};
        };
    };
};


