# AI Culler — Tuning Guide

## Quick Reference

| Variable | Default | Description |
|---|---|---|
| `AIC_maxActiveAI` | 80 | Hard cap on simultaneously active AI |
| `AIC_distOpfor` | 1000m | Cull distance for Opfor (east) |
| `AIC_distIndependent` | 800m | Cull distance for Independent |
| `AIC_distCivilian` | 400m | Cull distance for Civilians |
| `AIC_checkInterval` | 5s | How often the culler runs (seconds) |
| `AIC_debug` | true | RPT logging — disable for live ops |

---

## Changing Settings

### Mid-op (no rebuild needed)

Open Zeus → click **Settings** in the status window. Edit any value and click **Apply**. Changes take effect on the next culler tick and sync to all connected Zeus clients.

Use this to dial in values during a running op without restarting.

### Changing defaults (requires PBO rebuild)

Edit `@ai_culler/addons/aic_main/functions/fnc_preInit.sqf`. These are the values that load at mission start before any Zeus adjustments.

---

## Tuning by Op Size

### Small op (≤30 players, light AI)

```sqf
AIC_maxActiveAI = 120;
AIC_distOpfor   = 1200;
```

More players means more eyes on the battlefield — you can afford a higher cap and wider distance before performance suffers.

### Large op (60+ players, heavy AI)

```sqf
AIC_maxActiveAI = 80;
AIC_distOpfor   = 1000;
```

The defaults are tuned for this scenario.

### Dense civilian presence

```sqf
AIC_distCivilian = 300;
```

Civilians are cheap AI but still contribute to the count. Tightening their cull radius keeps headroom for the units that matter.

### Tight server headroom

```sqf
AIC_maxActiveAI  = 60;
AIC_checkInterval = 3;
```

Drop the cap further and check more frequently so the culler responds faster to player movement.

---

## Reading RPT Logs

With `AIC_debug = true` the following is logged every tick:

```
[AIC] Active: 74 / 80 | LOS: 12 | No-LOS: 62 | Out of range: 45 | Protected: 8 | Culled: 71
```

| Field | Meaning |
|---|---|
| Active | Total currently simulating |
| LOS | In range, at least one player has line of sight |
| No-LOS | In range but no player LOS |
| Out of range | Beyond faction cull distance — always disabled |
| Protected | Units marked zeusProtected — excluded from culling |
| Culled | Total disabled this tick |

If **Active** consistently hits the cap and **No-LOS** is large, lower `AIC_distOpfor` to shrink the no-LOS pool, or raise `AIC_maxActiveAI` if the server can handle it.

If **Out of range** is always near zero, your distances are tighter than needed — widen them to give Zeus more room to work with distant objectives.

Disable debug logging for live ops once you're happy with the tuning:

```sqf
// in fnc_preInit.sqf
AIC_debug = false;
```

---

## Zeus Protection

Units marked as protected are excluded from the culler pool entirely — they always simulate regardless of distance, LOS, or the active cap.

**Via script** (e.g. mission init or trigger):
```sqf
_unit setVariable ["zeusProtected", true, true];
```
