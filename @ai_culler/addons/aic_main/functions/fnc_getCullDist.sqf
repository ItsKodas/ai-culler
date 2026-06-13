params ["_unit"];

switch (side _unit) do {
    case east:       { AIC_distOpfor };
    case resistance: { AIC_distIndependent };
    case civilian:   { AIC_distCivilian };
    default:         { AIC_distOpfor };
};
