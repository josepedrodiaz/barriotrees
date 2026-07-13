#!/usr/bin/env bash
# Hook PreToolUse + PostToolUse + Stop de Claude Code.
# Claude está ejecutando trabajo → toca heartbeat-claude.txt. Mientras ese
# heartbeat esté fresco, el daemon cuenta el tiempo en la dimensión "claude"
# aunque el humano esté idle o con otra app en foco.
# Pre y Post juntos cubren tools largos (un build de 10 min toca al arrancar
# y al terminar); Stop cubre respuestas largas sin tools.
# Tiene que ser rápido: corre en cada tool call. Nada de python acá.
TDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
date +%s > "$TDIR/heartbeat-claude.txt" 2>/dev/null || true
exit 0
