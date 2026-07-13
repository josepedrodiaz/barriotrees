#!/usr/bin/env bash
# Hook UserPromptSubmit de Claude Code.
# 1. Toca heartbeat (timestamp epoch) + marker global de último proyecto
#    activo (el daemon lo usa para la dimensión "humano": si el último prompt
#    fue en otro proyecto, el tiempo humano no cuenta acá).
# 2. Si no hay timer activo + branch tiene KEY-XX → arranca timer.
# 3. Si no hay timer activo + branch NO tiene KEY-XX → emite warning visible.
#
# La KEY del proyecto se lee de config.json.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
TDIR="$PROJECT_ROOT/.claude/tiempo"
HEARTBEAT="$TDIR/heartbeat.txt"
TIMER="$TDIR/timer.py"
STATE="$TDIR/state.json"
CONFIG="$TDIR/config.json"

KEY="$(python3 -c "import json;print(json.load(open('$CONFIG'))['key'])" 2>/dev/null || echo TASK)"

# 1. Heartbeat + marker global (un prompt acá = la atención humana está acá)
mkdir -p "$TDIR"
date +%s > "$HEARTBEAT"
mkdir -p "$HOME/.config/claude"
echo "$PROJECT_ROOT" > "$HOME/.config/claude/tiempo-last-project.txt"

# 2. Auto-resume si hay auto_paused reciente
python3 "$TIMER" resume >/dev/null 2>&1 || true

# 3. Si ya hay timer activo, salir limpio
if [[ -f "$STATE" ]] && python3 -c "
import json, sys
try:
    with open('$STATE') as f:
        s = json.load(f)
    sys.exit(0 if s.get('active') else 1)
except Exception:
    sys.exit(1)
"; then
  exit 0
fi

# 4. No hay activo. Detectar branch
BRANCH="$(cd "$PROJECT_ROOT" && git branch --show-current 2>/dev/null || echo '')"

if [[ "$BRANCH" =~ (${KEY}-[0-9]+) ]]; then
  TICKET="${BASH_REMATCH[1]}"
  python3 "$TIMER" start "$TICKET" >/dev/null 2>&1 || true
  exit 0
fi

# 5. Branch sin KEY-XX → warning visible al modelo
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "⚠ tiempo: branch '$BRANCH' no tiene ${KEY}-XX, no se está trackeando tiempo. Si esto es trabajo de un ticket, ejecutá /track-start ${KEY}-XX o creá el ticket primero."
  }
}
EOF
