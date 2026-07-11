#!/usr/bin/env python3
"""
Timer local por ticket <KEY>-*. Source of truth = Jira worklog;
este script mantiene el intervalo abierto + cache de intervalos no sincronizados.

La key del proyecto y el offset horario se leen de config.json (junto a este
archivo). Sin config.json, defaults: key="TASK", tz=-3.

Comandos:
  timer.py start [KEY-XX]              → arranca timer (auto desde branch si no hay arg)
  timer.py stop                        → cierra timer, imprime JSON con el intervalo a sincronizar
  timer.py status                      → estado actual + acumulado del día
  timer.py list [--since YYYY-MM-DD]   → lista intervalos
  timer.py pending-sync                → lista intervalos con synced:false
  timer.py mark-synced <idx> <wlog_id> → marca intervalo como subido a Jira
  timer.py auto-pause <idle_seconds>   → cierra activo retroactivo: end = now - idle_seconds
  timer.py resume                      → reabre último auto_paused si < 1h
  timer.py prune-synced                → borra intervalos ya sincronizados (>30 días)
"""
import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone, timedelta
from pathlib import Path

STATE_DIR = Path(__file__).resolve().parent
STATE_FILE = STATE_DIR / "state.json"
HEARTBEAT_FILE = STATE_DIR / "heartbeat.txt"
CONFIG_FILE = STATE_DIR / "config.json"


def load_config():
    cfg = {"key": "TASK", "tz": -3}
    if CONFIG_FILE.exists():
        try:
            with CONFIG_FILE.open() as f:
                cfg.update(json.load(f))
        except Exception:
            pass
    return cfg


CFG = load_config()
KEY = str(CFG["key"]).upper()
TZ_LOCAL = timezone(timedelta(hours=CFG.get("tz", -3)))
TICKET_RE = re.compile(rf"({KEY}-\d+)", re.IGNORECASE)
TICKET_FULL_RE = re.compile(rf"{KEY}-\d+")


def load_state():
    if not STATE_FILE.exists():
        return {"active": None, "intervals": []}
    with STATE_FILE.open() as f:
        return json.load(f)


def save_state(state):
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    with STATE_FILE.open("w") as f:
        json.dump(state, f, indent=2, ensure_ascii=False)


def now_iso():
    return datetime.now(TZ_LOCAL).isoformat(timespec="seconds")


def parse_iso(s):
    return datetime.fromisoformat(s)


def fmt_minutes(m):
    m = int(round(m))
    h, mm = divmod(m, 60)
    if h:
        return f"{h}h {mm:02d}m"
    return f"{mm}m"


def detect_ticket_from_branch():
    cwd = STATE_DIR.parent.parent  # raíz del proyecto (.claude/tiempo → ../..)
    try:
        r = subprocess.run(
            ["git", "-C", str(cwd), "branch", "--show-current"],
            capture_output=True, text=True, check=True, timeout=5,
        )
        branch = r.stdout.strip()
    except Exception:
        return None, None
    m = TICKET_RE.search(branch)
    if not m:
        return None, branch
    return m.group(1).upper(), branch


def close_active(state, end_iso=None, auto_paused=False):
    """Cierra el timer activo y agrega un intervalo. Devuelve el intervalo.

    NUNCA descarta: si el end retroactivo cae antes del start (señal de idle
    contradictoria, ej heartbeat viejo), clampea end=start y marca
    needs_review para que se revise a mano en vez de perder el intervalo.
    """
    active = state.get("active")
    if not active:
        return None
    end = end_iso or now_iso()
    start_dt = parse_iso(active["started_at"])
    end_dt = parse_iso(end)
    needs_review = False
    if end_dt <= start_dt:
        end = active["started_at"]
        needs_review = True
        minutes = 1
    else:
        minutes = max(1, int(round((end_dt - start_dt).total_seconds() / 60)))
    interval = {
        "ticket": active["ticket"],
        "start": active["started_at"],
        "end": end,
        "minutes": minutes,
        "source": active.get("source", "manual"),
        "branch": active.get("started_branch"),
        "auto_paused": auto_paused,
        "needs_review": needs_review,
        "synced": False,
        "worklog_id": None,
    }
    state["intervals"].append(interval)
    state["active"] = None
    return interval


def touch_heartbeat():
    """Arrancar/reanudar un timer es actividad del proyecto: actualiza el
    heartbeat para que el daemon no auto-pause por un heartbeat viejo
    (sesiones abiertas fuera del proyecto no corren el hook que lo toca)."""
    try:
        HEARTBEAT_FILE.write_text(str(int(datetime.now().timestamp())))
    except Exception:
        pass


def cmd_start(args):
    state = load_state()
    ticket_arg = args[0] if args else None
    detected, branch = detect_ticket_from_branch()
    source = "manual" if ticket_arg else "branch"
    ticket = ticket_arg or detected

    if not ticket:
        print(json.dumps({
            "ok": False,
            "error": f"No se detectó {KEY}-XX en el branch ({branch!r}) y no pasaste ticket. Usá: timer.py start {KEY}-XX",
        }))
        return 1

    ticket = ticket.upper()
    if not TICKET_FULL_RE.fullmatch(ticket):
        print(json.dumps({"ok": False, "error": f"Ticket inválido: {ticket}"}))
        return 1

    # Si ya hay activo
    closed = None
    if state.get("active"):
        if state["active"]["ticket"] == ticket:
            print(json.dumps({
                "ok": True,
                "noop": True,
                "ticket": ticket,
                "started_at": state["active"]["started_at"],
                "message": f"Ya está corriendo {ticket} desde {state['active']['started_at']}",
            }, ensure_ascii=False))
            return 0
        closed = close_active(state)

    started = now_iso()
    state["active"] = {
        "ticket": ticket,
        "started_at": started,
        "started_branch": branch,
        "source": source,
    }
    save_state(state)
    touch_heartbeat()
    print(json.dumps({
        "ok": True,
        "started": {"ticket": ticket, "at": started, "source": source, "branch": branch},
        "closed": closed,
    }, ensure_ascii=False))
    return 0


def cmd_stop(args):
    state = load_state()
    if not state.get("active"):
        last = state["intervals"][-1] if state["intervals"] else None
        print(json.dumps({
            "ok": False,
            "error": "No hay timer activo",
            "last_interval": last,
        }, ensure_ascii=False))
        return 1
    closed = close_active(state)
    save_state(state)
    print(json.dumps({"ok": True, "closed": closed}, ensure_ascii=False))
    return 0


def cmd_status(args):
    state = load_state()
    today = datetime.now(TZ_LOCAL).date().isoformat()
    per_ticket = {}
    for iv in state["intervals"]:
        if iv["start"].startswith(today) or iv["end"].startswith(today):
            per_ticket[iv["ticket"]] = per_ticket.get(iv["ticket"], 0) + iv["minutes"]
    active = state.get("active")
    active_elapsed = 0
    if active:
        elapsed = (datetime.now(TZ_LOCAL) - parse_iso(active["started_at"])).total_seconds() / 60
        active_elapsed = int(round(elapsed))
        per_ticket[active["ticket"]] = per_ticket.get(active["ticket"], 0) + active_elapsed
    total = sum(per_ticket.values())
    print(json.dumps({
        "ok": True,
        "active": active,
        "active_elapsed_minutes": active_elapsed,
        "today_by_ticket": per_ticket,
        "today_total_minutes": total,
        "today": today,
    }, ensure_ascii=False))
    return 0


def cmd_list(args):
    state = load_state()
    since = None
    if "--since" in args:
        i = args.index("--since")
        since = args[i + 1]
    out = []
    for idx, iv in enumerate(state["intervals"]):
        if since and iv["start"] < since:
            continue
        out.append({"idx": idx, **iv})
    print(json.dumps({"ok": True, "intervals": out, "active": state.get("active")}, ensure_ascii=False))
    return 0


def cmd_mark_synced(args):
    state = load_state()
    idx = int(args[0])
    worklog_id = args[1] if len(args) > 1 else None
    if idx < 0 or idx >= len(state["intervals"]):
        print(json.dumps({"ok": False, "error": f"idx {idx} fuera de rango"}))
        return 1
    state["intervals"][idx]["synced"] = True
    state["intervals"][idx]["worklog_id"] = worklog_id
    save_state(state)
    print(json.dumps({"ok": True, "interval": state["intervals"][idx]}, ensure_ascii=False))
    return 0


def cmd_prune_synced(args):
    state = load_state()
    cutoff = (datetime.now(TZ_LOCAL) - timedelta(days=30)).isoformat()
    before = len(state["intervals"])
    state["intervals"] = [
        iv for iv in state["intervals"]
        if not (iv.get("synced") and iv["end"] < cutoff)
    ]
    save_state(state)
    print(json.dumps({"ok": True, "removed": before - len(state["intervals"])}))
    return 0


def cmd_auto_pause(args):
    """Cierra el timer activo con end = now - idle_seconds."""
    state = load_state()
    if not state.get("active"):
        print(json.dumps({"ok": False, "noop": True, "reason": "no active timer"}))
        return 0
    if not args:
        print(json.dumps({"ok": False, "error": "falta idle_seconds"}))
        return 1
    idle_s = int(args[0])
    end_dt = datetime.now(TZ_LOCAL) - timedelta(seconds=idle_s)
    end_iso = end_dt.isoformat(timespec="seconds")
    closed = close_active(state, end_iso=end_iso, auto_paused=True)
    save_state(state)
    print(json.dumps({"ok": True, "closed": closed}, ensure_ascii=False))
    return 0


def cmd_resume(args):
    """Reabre el último auto_paused si fue hace < 1h."""
    state = load_state()
    if state.get("active"):
        print(json.dumps({"ok": False, "error": "ya hay timer activo", "active": state["active"]}, ensure_ascii=False))
        return 1
    last = None
    for iv in reversed(state["intervals"]):
        if iv.get("auto_paused"):
            last = iv
            break
        # Si encontramos uno no-auto_paused primero, no reanudamos
        break
    if not last:
        print(json.dumps({"ok": False, "noop": True, "reason": "no hay auto_paused reciente"}))
        return 0
    end_dt = parse_iso(last["end"])
    age_min = (datetime.now(TZ_LOCAL) - end_dt).total_seconds() / 60
    if age_min > 60:
        print(json.dumps({"ok": False, "noop": True, "reason": f"auto_paused hace {int(age_min)}min (>60)"}))
        return 0
    # Reanudar: nuevo active con mismo ticket, started_at = ahora
    detected, branch = detect_ticket_from_branch()
    state["active"] = {
        "ticket": last["ticket"],
        "started_at": now_iso(),
        "started_branch": branch,
        "source": "resume",
    }
    save_state(state)
    touch_heartbeat()
    print(json.dumps({"ok": True, "resumed": state["active"], "after_pause_min": int(age_min)}, ensure_ascii=False))
    return 0


def cmd_pending_sync(args):
    """Lista intervalos con synced:false. Los needs_review van aparte:
    no se sincronizan automático, requieren revisión manual."""
    state = load_state()
    pending, review = [], []
    for i, iv in enumerate(state["intervals"]):
        if iv.get("synced"):
            continue
        (review if iv.get("needs_review") else pending).append({"idx": i, **iv})
    print(json.dumps({
        "ok": True,
        "pending": pending,
        "count": len(pending),
        "needs_review": review,
        "needs_review_count": len(review),
    }, ensure_ascii=False))
    return 0


COMMANDS = {
    "start": cmd_start,
    "stop": cmd_stop,
    "status": cmd_status,
    "list": cmd_list,
    "pending-sync": cmd_pending_sync,
    "mark-synced": cmd_mark_synced,
    "auto-pause": cmd_auto_pause,
    "resume": cmd_resume,
    "prune-synced": cmd_prune_synced,
}


def main():
    if len(sys.argv) < 2 or sys.argv[1] not in COMMANDS:
        print(__doc__)
        sys.exit(2)
    sys.exit(COMMANDS[sys.argv[1]](sys.argv[2:]))


if __name__ == "__main__":
    main()
