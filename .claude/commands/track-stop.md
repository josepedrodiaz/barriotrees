---
description: Cierra el timer activo y sube el intervalo a Jira como worklog.
---

# /track-stop — Parar timer activo

Cerrá el timer corriendo y subí el tiempo a Jira.

## Pasos

1. **Correr el stop:**
   ```bash
   python3 .claude/tiempo/timer.py stop
   ```
   Devuelve JSON `{ok, closed: {ticket, start, end, minutes, ...}}` o `{ok: false, error}` si no había nada activo.

2. **Si no había nada activo:** decir solo `no había timer activo` y terminar.

3. **Sincronizar a Jira** con `mcp__mcp-atlassian__jira_add_worklog`:
   - `issue_key` = `closed.ticket`
   - `time_spent` = minutos en formato Jira:
     - `< 60` → `"{m}m"`
     - `>= 60` → `"{h}h {m}m"` (omitir minutos si son 0)
   - `started` = `closed.start` convertido de `2026-05-26T15:30:00-03:00` a `2026-05-26T15:30:00.000-0300` (agregar `.000` y sacar el colon del offset)

4. **Si Jira responde con `id`:**
   ```bash
   python3 .claude/tiempo/timer.py mark-synced <idx> <worklog_id>
   ```
   Para saber el idx, correr `python3 .claude/tiempo/timer.py list` y usar el último (es `len(intervals) - 1`).

5. **Mensaje al usuario:**
   - OK: `⏹ BT-80 +45m subido a Jira`
   - Sync falló: `⏹ BT-80 +45m guardado local (Jira sync FALLÓ, queda en state.json)`

Una línea sola.
