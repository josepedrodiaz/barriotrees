---
description: Cierra el timer activo (ambas dimensiones) y sube los intervalos a Jira como worklogs.
---

# /track-stop — Parar timer activo

Cerrá el timer corriendo y subí el tiempo a Jira. El timer registra dos dimensiones (`humano` y `claude`) que pueden solaparse, así que el stop puede generar hasta dos intervalos.

## Pasos

1. **Correr el stop:**
   ```bash
   python3 .claude/tiempo/timer.py stop
   ```
   Devuelve JSON `{ok, closed: [{ticket, dimension, start, end, minutes, ...}, ...]}` o `{ok: false, error}` si no había nada activo.

2. **Si no había nada activo:** decir solo `no había timer activo` y terminar.

3. **Sincronizar cada intervalo de `closed`** con `mcp__mcp-atlassian__jira_add_worklog`:
   - `issue_key` = `ticket`
   - `time_spent` = minutos en formato Jira:
     - `< 60` → `"{m}m"`
     - `>= 60` → `"{h}h {m}m"` (omitir minutos si son 0)
   - `started` = `start` convertido de `2026-05-26T15:30:00-03:00` a `2026-05-26T15:30:00.000-0300` (agregar `.000` y sacar el colon del offset)
   - `comment` = `[humano]` o `[claude]` según el campo `dimension`

4. **Por cada worklog que Jira responda con `id`:**
   ```bash
   python3 .claude/tiempo/timer.py mark-synced <idx> <worklog_id>
   ```
   Para saber los idx, correr `python3 .claude/tiempo/timer.py pending-sync` (lista los no sincronizados con su idx).

5. **Mensaje al usuario:**
   - OK: `⏹ BT-80 +45m humano / +2h 10m claude subidos a Jira` (omitir la dimensión sin tiempo)
   - Sync falló: `⏹ BT-80 +45m humano guardado local (Jira sync FALLÓ, queda en state.json)`

Una línea sola.
