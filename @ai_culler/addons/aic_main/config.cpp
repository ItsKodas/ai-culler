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
            class preInit           { preInit  = 1; };
            class postInit          { postInit = 1; };
            class registerSettings  {};
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
            class updateUnitLabel      {};
            class createFpsGraphPanel  {};
            class renderFpsGraph       {};
        };
    };
};

class CfgSettings {
    class CBA {
        class Keybindings {};
        class Settings {
            class AI_Culler {
                name = "AI Culler";
                class AIC_cullerEnabled {
                    displayName = "Enable Culler on Start";
                    description = "Start the mission with the AI culling system active.";
                    typeName = "CHECKBOX";
                    isGlobal = 1;
                    value = 1;
                };
                class AIC_maxActiveAI {
                    displayName = "Max Active AI";
                    description = "Maximum number of AI units the culler allows to be active simultaneously.";
                    typeName = "SLIDER";
                    isGlobal = 1;
                    value = 150;
                    sliderMin = 10;
                    sliderMax = 500;
                    sliderStep = 1;
                    sliderDecimalPlaces = 0;
                };
                class AIC_distBlufor {
                    displayName = "BLUFOR Cull Distance (m)";
                    description = "Distance beyond which BLUFOR AI infantry are culled.";
                    typeName = "SLIDER";
                    isGlobal = 1;
                    value = 2000;
                    sliderMin = 100;
                    sliderMax = 8000;
                    sliderStep = 50;
                    sliderDecimalPlaces = 0;
                };
                class AIC_distOpfor {
                    displayName = "OPFOR Cull Distance (m)";
                    description = "Distance beyond which OPFOR AI infantry are culled.";
                    typeName = "SLIDER";
                    isGlobal = 1;
                    value = 2000;
                    sliderMin = 100;
                    sliderMax = 8000;
                    sliderStep = 50;
                    sliderDecimalPlaces = 0;
                };
                class AIC_distIndependent {
                    displayName = "Independent Cull Distance (m)";
                    description = "Distance beyond which Independent AI infantry are culled.";
                    typeName = "SLIDER";
                    isGlobal = 1;
                    value = 2000;
                    sliderMin = 100;
                    sliderMax = 8000;
                    sliderStep = 50;
                    sliderDecimalPlaces = 0;
                };
                class AIC_distCivilian {
                    displayName = "Civilian Cull Distance (m)";
                    description = "Distance beyond which Civilian AI are culled. Set to 0 to always cull civilians.";
                    typeName = "SLIDER";
                    isGlobal = 1;
                    value = 500;
                    sliderMin = 0;
                    sliderMax = 3000;
                    sliderStep = 50;
                    sliderDecimalPlaces = 0;
                };
                class AIC_checkInterval {
                    displayName = "Check Interval (s)";
                    description = "How often (in seconds) the culler re-evaluates all AI units.";
                    typeName = "SLIDER";
                    isGlobal = 1;
                    value = 5;
                    sliderMin = 1;
                    sliderMax = 30;
                    sliderStep = 1;
                    sliderDecimalPlaces = 0;
                };
                class AIC_minActiveRadius {
                    displayName = "Min Active Radius (m)";
                    description = "AI within this distance of any player are always active, skipping the LOS check.";
                    typeName = "SLIDER";
                    isGlobal = 1;
                    value = 200;
                    sliderMin = 25;
                    sliderMax = 1000;
                    sliderStep = 25;
                    sliderDecimalPlaces = 0;
                };
                class AIC_combatRadius {
                    displayName = "Combat Detection Radius (m)";
                    description = "Radius used to detect whether AI units are in active combat with each other.";
                    typeName = "SLIDER";
                    isGlobal = 1;
                    value = 400;
                    sliderMin = 50;
                    sliderMax = 1500;
                    sliderStep = 50;
                    sliderDecimalPlaces = 0;
                };
                class AIC_debug {
                    displayName = "Debug Logging";
                    description = "Write culler diagnostics to the RPT log each tick.";
                    typeName = "CHECKBOX";
                    isGlobal = 1;
                    value = 0;
                };
            };
            class AI_Culler_Client {
                name = "AI Culler - Client";
                class AIC_showLabels {
                    displayName = "Show Unit Name Labels";
                    description = "Prefix unit names with [Culled] / [Protected] / [Override] when you are Zeus.";
                    typeName = "CHECKBOX";
                    isGlobal = 0;
                    value = 1;
                };
                class AIC_show3DLabels {
                    displayName = "Show 3D Floating Labels";
                    description = "Draw floating 3D text labels above culled/protected/override units in Zeus view.";
                    typeName = "CHECKBOX";
                    isGlobal = 0;
                    value = 1;
                };
                class AIC_labelDist {
                    displayName = "3D Label Draw Distance (m)";
                    description = "Maximum distance from your camera at which 3D labels are rendered.";
                    typeName = "SLIDER";
                    isGlobal = 0;
                    value = 800;
                    sliderMin = 100;
                    sliderMax = 3000;
                    sliderStep = 50;
                    sliderDecimalPlaces = 0;
                };
            };
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
