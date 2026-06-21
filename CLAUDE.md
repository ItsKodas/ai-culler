# AI Culler — Claude Instructions

## SQF Database Research (Required)

Before writing or modifying any SQF code, always search the Arma 3 documentation database to verify commands, syntax, return types, and version availability.

The database is at `docs/arma3.db`. Use the search script:

```bash
python docs/search_arma3.py "<command name>"
```

Or query the database directly for full details:

```bash
python -c "
import sqlite3
conn = sqlite3.connect('docs/arma3.db')
cur = conn.cursor()
cur.execute(\"SELECT title, syntax, params, returns, descr FROM commands WHERE title = '<command>'\")
row = cur.fetchone()
if row:
    print('Syntax:', row[1])
    print('Params:', row[2])
    print('Returns:', row[3])
    print('Descr:', row[4])
conn.close()
"
```

Always verify:
- The command exists in Arma 3 (not ArmA 2 only)
- The correct syntax and parameter order
- What the command returns (especially null/objNull cases)
- The `since` version to ensure compatibility

If the database returns no result or truncated info, flag the uncertainty rather than assuming.

## Project Overview

AI Culler is a two-part Arma 3 performance mod:
- `aic_main` — server-side AI simulation culler + Zeus UI (`@ai_culler/addons/aic_main/`)
- `aic_client` — client-side model renderer using `hideObject` (`@ai_culler/addons/aic_client/`)

## Key Conventions

- All variables use the `AIC_` prefix
- Functions are registered under the `AIC` tag via `CfgFunctions`
- Server-side changes go in `aic_main`, client-side in `aic_client`
- `vehicle _x == _x` guards exclude vehicle crew/passengers from infantry pools
- `!isNull (remoteControlled _unit)` detects Zeus remote-controlled units
- Only reveal units aic_client itself hid — check `AIC_clientHid` variable before calling `hideObject false`
