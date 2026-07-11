---
description: Arranca timer en un ticket BT-*. Sin args detecta el ticket del branch git actual. Cierra el timer previo si hay otro corriendo.
argument-hint: "[BT-XX] (opcional, default: detectado del branch)"
---

# /track-start — Arrancar timer

Arrancá un timer para trackear tiempo en un ticket BT-*. El intervalo se cierra con `/track-stop` (o cuando arranqués otro `/track-start`) y se sincroniza a Jira como worklog automáticamente.

## Cómo funciona

- **Sin argumento:** detecta `BT-XX` del branch git actual (ej: `sprint-1/bt-80-algo` → `BT-80`).
- **Con argumento:** `/track-start BT-80` arranca ese ticket aunque el branch no lo mencione.
- **Si ya hay otro timer activo:** lo cierra primero (sube worklog) y arranca el nuevo.
- **Si el mismo ticket ya está activo:** no hace nada (no-op).

## Pasos

1. **Correr el timer:**
   ```bash
   python3 .claude/tiempo/timer.py start $ARGUMENTS
   ```
   El script devuelve JSON con `started` (y opcionalmente `closed` si cerró uno previo).

2. **Si cerró un timer previo (`closed` no es null):**
   - Sincronizar el intervalo a Jira con `mcp__mcp-atlassian__jira_add_worklog`:
     - `issue_key` = `closed.ticket`
     - `time_spent` = formato Jira (ej "45m", "1h 30m") calculado desde `closed.minutes`
     - `started` = `closed.start` (ISO con zona, sin colon en offset: `YYYY-MM-DDTHH:MM:SS.000-0300`)
   - Si el `add_worklog` devuelve `id`, marcar el intervalo como sincronizado:
     ```bash
     python3 .claude/tiempo/timer.py mark-synced <idx> <worklog_id>
     ```
   - Si el `add_worklog` falla: NO marcar como sincronizado. Avisar que el worklog quedó solo en local.

3. **Conversión de minutos a formato Jira:**
   - `< 60` → `"{m}m"` (ej "45m")
   - `>= 60` → `"{h}h {m}m"` con minutos solo si > 0 (ej "1h 30m", "2h")

4. **Formato de `started` para Jira:**
   El timer devuelve ISO con colon en offset: `2026-05-26T15:30:00-03:00`.
   Jira lo quiere: `2026-05-26T15:30:00.000-0300` (agregar `.000` y quitar el `:` del offset).

5. **Mensaje al usuario (una línea):**
   - Si solo arrancó: `⏱ BT-80 corriendo (desde branch)` o `(manual)`
   - Si además cerró uno: `⏹ BT-79 +45m a Jira · ⏱ BT-80 corriendo`
   - Si Jira sync falló: `⏹ BT-79 +45m (sync Jira FALLÓ, queda local) · ⏱ BT-80 corriendo`

No expliques pasos. Una línea sola.
