# AI Culler — Setup & Tuning Guide

## Installation

1. Copy the `ai-culler` folder into your mission directory
2. Add the following to your mission's `init.sqf`:

```sqf
if (isServer) then {
    [] spawn {
        sleep 5;
        call compile preprocessFileLineNumbers "src\AI_Culler.sqf";
    };
};
```

If you already have an `init.sqf`, just append those lines.

---

## Configuration

All tunable values are in `config/settings.sqf`.

| Variable | Default | Description |
|---|---|---|
| `AI_Culler_maxActiveAI` | 80 | Hard cap on simultaneously active AI across all factions |
| `AI_Culler_distOpfor` | 1000m | Cull distance for Opfor (east) |
| `AI_Culler_distIndependent` | 800m | Cull distance for Independent (resistance) |
| `AI_Culler_distCivilian` | 400m | Cull distance for Civilians |
| `AI_Culler_checkInterval` | 5s | How often the culler runs |
| `AI_Culler_debug` | true | RPT logging on/off |

---

## Tuning Per Mission

### Small op (30 players, light AI)
```sqf
AI_Culler_maxActiveAI = 120;
AI_Culler_distOpfor   = 1200;
```

### Large op (60 players, heavy AI)
```sqf
AI_Culler_maxActiveAI = 80;
AI_Culler_distOpfor   = 1000;
```

### Dense civilian presence
```sqf
AI_Culler_distCivilian = 300; // Tighten further to reduce overhead
```

---

## Zeus Usage

Any unit placed by Zeus via the curator interface is automatically flagged as protected and will never be culled.

To manually protect a pre-placed unit add to its init line:
```sqf
this setVariable ["zeusProtected", true, true];
```

---

## Reading RPT Logs

With `AI_Culler_debug = true` the following is logged every cycle:

```
[AI_Culler] Active: 74 / 80 | LOS: 12 | No-LOS: 62 | Out of range: 45 | Culled: 71
```

| Field | Meaning |
|---|---|
| Active | Total currently simulating |
| LOS | Units visible to at least one player |
| No-LOS | In range but no player LOS |
| Out of range | Beyond faction cull distance |
| Culled | Total disabled this cycle |

Turn off debug logging for live ops once you're happy with the tuning:
```sqf
AI_Culler_debug = false;
```

---

## Compatibility

- ✅ LAMBS Danger
- ✅ Headless Clients (run culler on server, HC owns groups as normal)
- ✅ Civilian Presence Module
- ✅ Zeus / Curator
- ✅ ACE3
- ⚠️ Vcom AI — not tested, may conflict
