#!/usr/bin/env bash
# Hook SessionStart de Claude Code.
# 1. Flusha intervalos pending-sync a Jira (vía el modelo en la próxima respuesta:
#    inyecta additionalContext con la lista para que llame jira_add_worklog).
# 2. Auto-arranca timer si branch tiene KEY-XX (igual que UserPromptSubmit).
#
# La KEY del proyecto se lee de config.json.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
TDIR="$PROJECT_ROOT/.claude/tiempo"
HEARTBEAT="$TDIR/heartbeat.txt"
TIMER="$TDIR/timer.py"
CONFIG="$TDIR/config.json"

KEY="$(python3 -c "import json;print(json.load(open('$CONFIG'))['key'])" 2>/dev/null || echo TASK)"

mkdir -p "$TDIR"
date +%s > "$HEARTBEAT"
# Marker global: abrir sesión acá = la atención humana está acá
mkdir -p "$HOME/.config/claude"
echo "$PROJECT_ROOT" > "$HOME/.config/claude/tiempo-last-project.txt"

# Auto-resume si auto_paused reciente
python3 "$TIMER" resume >/dev/null 2>&1 || true

# Auto-arranca si no hay activo + branch con KEY-XX
BRANCH="$(cd "$PROJECT_ROOT" && git branch --show-current 2>/dev/null || echo '')"
if [[ "$BRANCH" =~ (${KEY}-[0-9]+) ]]; then
  python3 "$TIMER" start "${BASH_REMATCH[1]}" >/dev/null 2>&1 || true
fi

# Listar intervalos pending-sync para que el modelo los suba a Jira
PENDING="$(python3 "$TIMER" pending-sync 2>/dev/null || echo '{"count":0}')"
COUNT="$(echo "$PENDING" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("count",0))' 2>/dev/null || echo 0)"

if [[ "$COUNT" != "0" ]]; then
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "tiempo: hay $COUNT intervalos pendientes de sincronizar a Jira. Datos JSON:\n\n$PENDING\n\nPara cada uno, llamá mcp__mcp-atlassian__jira_add_worklog con issue_key=ticket, time_spent=minutos formateado, started=start convertido a 'YYYY-MM-DDTHH:MM:SS.000±HHMM' (sin colon en offset, agregar .000), y comment='[<dimension>]' usando el campo dimension del intervalo ('[humano]' si falta). Después de cada sync exitoso, correr: python3 .claude/tiempo/timer.py mark-synced <idx> <worklog_id>"
  }
}
EOF
fi
