---
description: Arranca timer en un ticket BT-*. Sin args detecta el ticket del branch git actual. Cierra el timer previo si hay otro corriendo.
argument-hint: "[BT-XX] (opcional, default: detectado del branch)"
---

# /track-start — Arrancar timer

Arrancá un timer para trackear tiempo en un ticket BT-*. El tiempo se registra en dos dimensiones que pueden solaparse: `humano` (el usuario presente en la sesión) y `claude` (Claude ejecutando trabajo). Cada dimensión genera sus propios intervalos, que se suben a Jira como worklogs separados.

## Cómo funciona

- **Sin argumento:** detecta `BT-XX` del branch git actual (ej: `sprint-1/bt-80-algo` → `BT-80`).
- **Con argumento:** `/track-start BT-80` arranca ese ticket aunque el branch no lo mencione.
- **Si ya hay otro timer activo:** lo cierra primero (puede generar varios intervalos, uno por dimensión) y arranca el nuevo.
- **Si el mismo ticket ya está activo:** no hace nada (no-op).

## Pasos

1. **Correr el timer:**
   ```bash
   python3 .claude/tiempo/timer.py start $ARGUMENTS
   ```
   El script devuelve JSON con `started` y `closed` (lista de intervalos del ticket previo, vacía si no había otro corriendo).

2. **Si `closed` tiene intervalos**, sincronizar cada uno a Jira con `mcp__mcp-atlassian__jira_add_worklog`:
   - `issue_key` = `ticket` del intervalo
   - `time_spent` = formato Jira calculado desde `minutes` (ej "45m", "1h 30m")
   - `started` = `start` del intervalo (ISO con zona, sin colon en offset: `YYYY-MM-DDTHH:MM:SS.000-0300`)
   - `comment` = `[humano]` o `[claude]` según el campo `dimension` del intervalo
   - Para saber el `idx` de cada intervalo, correr `python3 .claude/tiempo/timer.py pending-sync` (lista los no sincronizados con su idx).
   - Si el `add_worklog` devuelve `id`, marcar el intervalo:
     ```bash
     python3 .claude/tiempo/timer.py mark-synced <idx> <worklog_id>
     ```
   - Si un `add_worklog` falla: NO marcar como sincronizado. Avisar que ese worklog quedó solo en local.

3. **Conversión de minutos a formato Jira:**
   - `< 60` → `"{m}m"` (ej "45m")
   - `>= 60` → `"{h}h {m}m"` con minutos solo si > 0 (ej "1h 30m", "2h")

4. **Formato de `started` para Jira:**
   El timer devuelve ISO con colon en offset: `2026-05-26T15:30:00-03:00`.
   Jira lo quiere: `2026-05-26T15:30:00.000-0300` (agregar `.000` y quitar el `:` del offset).

5. **Mensaje al usuario (una línea):**
   - Si solo arrancó: `⏱ BT-80 corriendo (desde branch)` o `(manual)`
   - Si además cerró intervalos: `⏹ BT-79 +45m humano / +1h 20m claude a Jira · ⏱ BT-80 corriendo` (omitir la dimensión que no tenga tiempo)
   - Si Jira sync falló: `⏹ BT-79 +45m humano (sync Jira FALLÓ, queda local) · ⏱ BT-80 corriendo`

No expliques pasos. Una línea sola.
