#!/usr/bin/env python3
"""
Daemon que corre cada 60s vía launchd. Junta señales y se las pasa a
`timer.py tick`, que maneja las dos dimensiones de tiempo:

  humano: input reciente (ioreg) + app de la sesión en foco (config
          focus_apps, via lsappinfo/osascript) + este proyecto fue el último
          en recibir un prompt (marker ~/.config/claude/tiempo-last-project.txt)
  claude: heartbeat-claude.txt fresco (lo tocan los hooks
          PreToolUse/PostToolUse/Stop mientras Claude ejecuta trabajo)

Acá viven solo los sensores; la máquina de estados y la escritura de
state.json viven en timer.py. No sube nada a Jira; eso lo hace el
SessionStart hook la próxima vez que abrís Claude.

Log: .claude/tiempo/daemon.log
"""
import json
import re
import subprocess
import sys
from datetime import datetime, timezone, timedelta
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PROJECT_ROOT = ROOT.parent.parent
HEARTBEAT_CLAUDE_FILE = ROOT / "heartbeat-claude.txt"
LOG_FILE = ROOT / "daemon.log"
TIMER = ROOT / "timer.py"
CONFIG_FILE = ROOT / "config.json"
MARKER_FILE = Path.home() / ".config" / "claude" / "tiempo-last-project.txt"

DEFAULT_FOCUS_APPS = ["Terminal", "iTerm2", "Claude", "Code", "Cursor", "Ghostty", "Warp"]


def _cfg():
    cfg = {}
    if CONFIG_FILE.exists():
        try:
            with CONFIG_FILE.open() as f:
                cfg = json.load(f)
        except Exception:
            pass
    return cfg


CFG = _cfg()
TZ_LOCAL = timezone(timedelta(hours=CFG.get("tz", -3)))
FOCUS_APPS = [str(a).lower() for a in CFG.get("focus_apps", DEFAULT_FOCUS_APPS)]


def log(msg):
    ts = datetime.now(TZ_LOCAL).isoformat(timespec="seconds")
    with LOG_FILE.open("a") as f:
        f.write(f"[{ts}] {msg}\n")


def system_idle_seconds():
    """Segundos sin input en macOS (mouse/teclado) via ioreg."""
    try:
        out = subprocess.check_output(
            ["ioreg", "-c", "IOHIDSystem"], text=True, timeout=5
        )
    except Exception as e:
        log(f"ioreg falló: {e}")
        return 0
    # "HIDIdleTime" = 1750000000000  (nanosegundos)
    m = re.search(r'"HIDIdleTime"\s*=\s*(\d+)', out)
    if not m:
        log("HIDIdleTime no encontrado en ioreg")
        return 0
    return int(m.group(1)) // 1_000_000_000


def frontmost_app():
    """Nombre de la app en foco. lsappinfo primero (no pide permisos),
    osascript de fallback. None si ninguno funcionó."""
    try:
        asn = subprocess.check_output(["lsappinfo", "front"], text=True, timeout=5).strip()
        if asn:
            info = subprocess.check_output(
                ["lsappinfo", "info", "-only", "name", asn], text=True, timeout=5
            )
            m = re.search(r'"LSDisplayName"\s*=\s*"([^"]+)"', info)
            if m:
                return m.group(1)
    except Exception:
        pass
    try:
        out = subprocess.check_output(
            ["osascript", "-e",
             'tell application "System Events" to get name of first application process whose frontmost is true'],
            text=True, timeout=5,
        ).strip()
        return out or None
    except Exception:
        return None


def frontmost_ok():
    """True si la app en foco es de la sesión (focus_apps, case-insensitive).
    Si la detección falla, fail-open: mejor contar de más que repetir el bug
    de perder horas de trabajo real."""
    name = frontmost_app()
    if name is None:
        log("frontmost: detección falló (lsappinfo y osascript) → asumo foco OK")
        return True, None
    return name.lower() in FOCUS_APPS, name


def project_marker_ok():
    """True si este proyecto es el último que recibió un prompt (marker global).
    Sin marker (hooks viejos u otro setup) no bloquea. Acepta prefijos en
    ambos sentidos para cubrir worktrees debajo del proyecto."""
    if not MARKER_FILE.exists():
        return True
    try:
        marker = str(Path(MARKER_FILE.read_text().strip()).resolve())
        mine = str(PROJECT_ROOT.resolve())
    except Exception:
        return True
    return marker == mine or marker.startswith(mine + "/") or mine.startswith(marker + "/")


def claude_hb_age_seconds():
    """Segundos desde el último heartbeat de actividad de Claude. -1 = nunca."""
    if not HEARTBEAT_CLAUDE_FILE.exists():
        return -1
    try:
        ts = int(HEARTBEAT_CLAUDE_FILE.read_text().strip())
        return int(datetime.now().timestamp()) - ts
    except Exception as e:
        log(f"heartbeat-claude falló: {e}")
        return -1


def get_active():
    """Lee state.json directamente para no spawnear timer.py."""
    state_file = ROOT / "state.json"
    if not state_file.exists():
        return None
    try:
        with state_file.open() as f:
            return json.load(f).get("active")
    except Exception:
        return None


def main():
    if not get_active():
        # No hay timer activo → nada que hacer
        return 0

    sys_idle = system_idle_seconds()
    f_ok, front_name = frontmost_ok()
    p_ok = project_marker_ok()
    hb_age = claude_hb_age_seconds()

    r = subprocess.run(
        ["python3", str(TIMER), "tick",
         str(sys_idle), "1" if f_ok else "0", "1" if p_ok else "0", str(hb_age)],
        capture_output=True, text=True, timeout=10,
    )
    if r.returncode != 0:
        log(f"timer.py tick FAILED: {r.stderr.strip()}")
        return 0
    try:
        out = json.loads(r.stdout.strip() or "{}")
    except Exception:
        log(f"tick output ilegible: {r.stdout.strip()}")
        return 0
    events = out.get("events") or []
    if events:
        log(
            f"TICK sys_idle={sys_idle}s front={front_name!r}({'ok' if f_ok else 'no'}) "
            f"proj={'ok' if p_ok else 'no'} hb_claude={hb_age}s → " + "; ".join(events)
        )
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as e:
        log(f"FATAL: {e}")
        sys.exit(1)
