// Register CBA Addon Options settings first so variables have user-configured
// values before any other code runs. No-op if CBA_A3 is not loaded.
[] call AIC_fnc_registerSettings;

// Hard-coded defaults — only applied for variables still undefined after the
// CBA registration above (i.e. CBA is absent, or a variable was not registered).
if (isNil "AIC_maxActiveAI")      then { AIC_maxActiveAI     = 200   };
if (isNil "AIC_distBlufor")       then { AIC_distBlufor      = 2000  };
if (isNil "AIC_distOpfor")        then { AIC_distOpfor       = 2000  };
if (isNil "AIC_distIndependent")  then { AIC_distIndependent = 2000  };
if (isNil "AIC_distCivilian")     then { AIC_distCivilian    = 500   };
if (isNil "AIC_checkInterval")    then { AIC_checkInterval   = 5     };
if (isNil "AIC_minActiveRadius")  then { AIC_minActiveRadius = 200   };
if (isNil "AIC_combatRadius")     then { AIC_combatRadius    = 400   };
if (isNil "AIC_debug")            then { AIC_debug           = false };
if (isNil "AIC_cullerEnabled")    then { AIC_cullerEnabled   = true  };

// Client renderer defaults (also fall back here without CBA)
if (isNil "AIC_showLabels")   then { AIC_showLabels   = true };
if (isNil "AIC_show3DLabels") then { AIC_show3DLabels = true };
if (isNil "AIC_labelDist")    then { AIC_labelDist    = 800  };

if (AIC_debug) then { diag_log "[AIC] Settings initialised" };
