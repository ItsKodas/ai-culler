class CfgPatches {
    class aic_client {
        name = "AI Culler — Client Renderer";
        author = "koda";
        url = "";
        units[] = {};
        weapons[] = {};
        requiredVersion = 1.98;
        requiredAddons[] = {"cba_main"};
        version = "1.0.0";
        versionStr = "1.0.0";
        versionAr[] = {1, 0, 0};
    };
};

class CfgFunctions {
    class AIC_Client {
        tag = "AIC";
        class Client {
            file = "aic_client\functions";
            class clientPreInit    { preInit = 1; };
            class clientLoop       {};
            class clientZeusHooks  {};
            class createClientPanel {};
        };
    };
};
