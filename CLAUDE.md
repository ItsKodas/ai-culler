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

## Documentation Updates (Required Before Committing)

Before committing any significant code change (new feature, bug fix, behaviour change), update all four of the following. Do this before the commit, not after.

### 1. `README.md` changelog
Add an entry under the current version heading (or create a new version heading if one does not exist). Follow the existing format — bullet points, backtick-wrapped command/variable names, concise descriptions of what changed and why.

### 2. `workshop_changenotes.txt`
Add a new version heading at the top of the file (e.g. `[h1]v3.9.0[/h1]`) with a `[list]` of bullet points covering what changed. Use Steam BBCode — `[b]`, `[list]`, `[*]`, `[h1]`. Keep wording plain and direct, no em dashes, no AI-sounding language. Do not remove old entries.

### 3. `workshop_description.txt`
Update any sections affected by the change:
- If a new feature was added, add it to the `[h1]Features[/h1]` list
- If `aic_main` or `aic_client` behaviour changed, update the `[h1]The Solution[/h1]` description
- If the Zeus UI changed, update `[h1]Live Zeus Control[/h1]`
- Use Steam BBCode formatting (`[b]`, `[list]`, `[*]`, `[h1]`, etc.) — match the style of the existing file
- No em dashes — use commas instead
- Keep the tone natural, not AI-sounding

### 4. Version
If changes are significant enough to warrant a version bump, update `versionStr` and `versionAr` in `@ai_culler/addons/aic_main/config.cpp` and `@ai_culler/addons/aic_client/config.cpp`.

**What counts as significant:** anything that changes gameplay behaviour, fixes a visible bug, adds a feature, or changes a public API. Pure refactors or comment changes do not need doc updates.

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
