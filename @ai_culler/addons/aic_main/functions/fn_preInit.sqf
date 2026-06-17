// Hard-coded defaults — applied when CBA_A3 is not loaded or a variable has
// not yet been populated by CBA (CBA registration happens in postInit).
if (isNil "AIC_maxActiveAI")      then { AIC_maxActiveAI     = 150   };
if (isNil "AIC_distBlufor")       then { AIC_distBlufor      = 2000  };
if (isNil "AIC_distOpfor")        then { AIC_distOpfor       = 2000  };
if (isNil "AIC_distIndependent")  then { AIC_distIndependent = 2000  };
if (isNil "AIC_distCivilian")     then { AIC_distCivilian    = 500   };
if (isNil "AIC_checkInterval")    then { AIC_checkInterval   = 5     };
if (isNil "AIC_minActiveRadius")  then { AIC_minActiveRadius = 200   };
if (isNil "AIC_combatRadius")     then { AIC_combatRadius    = 400   };
if (isNil "AIC_debug")            then { AIC_debug           = false };
if (isNil "AIC_cullerEnabled")       then { AIC_cullerEnabled      = true };
if (isNil "AIC_showNotifications")   then { AIC_showNotifications  = true };

// Client renderer defaults (also fall back here without CBA)
if (isNil "AIC_showLabels")   then { AIC_showLabels   = true };
if (isNil "AIC_show3DLabels") then { AIC_show3DLabels = true };
if (isNil "AIC_labelDist")    then { AIC_labelDist    = 800  };

if (AIC_debug) then { diag_log "[AIC] Settings initialised" };
