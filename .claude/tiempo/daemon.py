#!/usr/bin/env python3
"""
Daemon que corre cada 60s vía launchd. Auto-pausa el timer si:
  max(system_idle, heartbeat_idle) > THRESHOLD_MINUTES

system_idle = segundos sin input en macOS (ioreg)
heartbeat_idle = segundos desde el último UserPromptSubmit hook de Claude Code
                 en este proyecto (archivo .claude/tiempo/heartbeat.txt)

Si auto-pausa: cierra el intervalo con end = now - max_idle (último momento activo).
No sube a Jira; eso lo hace el SessionStart hook la próxima vez que abrís Claude.

El offset horario se lee de config.json (default -3).

Log: .claude/tiempo/daemon.log
"""
import json
import re
import subprocess
import sys
from datetime import datetime, timezone, timedelta
from pathlib import Path

THRESHOLD_MINUTES = 15

ROOT = Path(__file__).resolve().parent
HEARTBEAT_FILE = ROOT / "heartbeat.txt"
LOG_FILE = ROOT / "daemon.log"
TIMER = ROOT / "timer.py"
CONFIG_FILE = ROOT / "config.json"


def _tz():
    off = -3
    if CONFIG_FILE.exists():
        try:
            with CONFIG_FILE.open() as f:
                off = json.load(f).get("tz", -3)
        except Exception:
            pass
    return timezone(timedelta(hours=off))


TZ_LOCAL = _tz()


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


def heartbeat_idle_seconds():
    """Segundos desde el último heartbeat de Claude Code en este proyecto."""
    if not HEARTBEAT_FILE.exists():
        return float("inf")  # nunca hubo heartbeat → considerar idle infinito
    try:
        with HEARTBEAT_FILE.open() as f:
            ts = int(f.read().strip())
        return int(datetime.now().timestamp()) - ts
    except Exception as e:
        log(f"heartbeat falló: {e}")
        return float("inf")


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
    active = get_active()
    if not active:
        # No hay timer activo → nada que hacer
        return 0

    sys_idle = system_idle_seconds()
    hb_idle = heartbeat_idle_seconds()
    effective_idle = max(sys_idle, hb_idle if hb_idle != float("inf") else 0)
    # Si heartbeat es infinity (nunca hubo), usamos solo sys_idle
    if hb_idle == float("inf"):
        effective_idle = sys_idle

    threshold_s = THRESHOLD_MINUTES * 60

    if effective_idle < threshold_s:
        # Activo trabajando, no hacer nada
        return 0

    # Auto-pausar
    log(f"AUTO-PAUSE: ticket={active['ticket']} sys_idle={sys_idle}s hb_idle={hb_idle}s effective={effective_idle}s")
    r = subprocess.run(
        ["python3", str(TIMER), "auto-pause", str(effective_idle)],
        capture_output=True, text=True, timeout=10,
    )
    log(f"  timer.py auto-pause output: {r.stdout.strip()}")
    if r.returncode != 0:
        log(f"  timer.py FAILED: {r.stderr.strip()}")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as e:
        log(f"FATAL: {e}")
        sys.exit(1)
