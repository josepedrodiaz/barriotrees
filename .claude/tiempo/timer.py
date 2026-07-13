#!/usr/bin/env python3
"""
Timer local por ticket <KEY>-* con dos dimensiones de tiempo:

  humano: el usuario está en la sesión (input reciente + app en foco +
          este proyecto es el último que recibió un prompt)
  claude: Claude está ejecutando trabajo (heartbeat-claude.txt fresco,
          tocado por los hooks PreToolUse/PostToolUse/Stop)

Las dimensiones corren en paralelo y pueden solaparse. Cada una genera sus
propios intervalos (campo "dimension") que se suben a Jira como worklogs
separados con comment "[humano]" / "[claude]".

El estado vive en state.json. Este script es el ÚNICO que lo escribe; el
daemon solo junta sensores y llama a `tick`.

La key del proyecto y el offset horario se leen de config.json (junto a este
archivo). Sin config.json, defaults: key="TASK", tz=-3. Config opcional:
focus_apps, humano_pause_min (15), claude_pause_min (10).

Comandos:
  timer.py start [KEY-XX]              → arranca timer (auto desde branch si no hay arg)
  timer.py stop                        → cierra dimensiones abiertas, imprime intervalos a sincronizar
  timer.py status                      → estado actual + acumulado del día por dimensión
  timer.py list [--since YYYY-MM-DD]   → lista intervalos
  timer.py pending-sync                → lista intervalos con synced:false
  timer.py mark-synced <idx> <wlog_id> → marca intervalo como subido a Jira
  timer.py tick <sys_idle_s> <front_ok:0|1> <proj_ok:0|1> <claude_hb_age_s|-1>
                                       → un paso de la máquina de estados (lo llama el daemon)
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
PROJECT_ROOT = STATE_DIR.parent.parent
STATE_FILE = STATE_DIR / "state.json"
HEARTBEAT_FILE = STATE_DIR / "heartbeat.txt"
CONFIG_FILE = STATE_DIR / "config.json"
MARKER_FILE = Path.home() / ".config" / "claude" / "tiempo-last-project.txt"


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
HUMANO_PAUSE_S = int(CFG.get("humano_pause_min", 15)) * 60
CLAUDE_PAUSE_S = int(CFG.get("claude_pause_min", 10)) * 60


def load_state():
    if not STATE_FILE.exists():
        return {"active": None, "intervals": []}
    with STATE_FILE.open() as f:
        state = json.load(f)
    # Migración v1 → v2 (en memoria; se persiste con el próximo comando que escriba)
    for iv in state.get("intervals", []):
        iv.setdefault("dimension", "humano")
    active = state.get("active")
    if active is not None and "dims" not in active:
        # v1: "active" significaba humano trabajando desde started_at
        active["dims"] = {"humano": {"since": active["started_at"], "last": now_iso()}}
    return state


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
    try:
        r = subprocess.run(
            ["git", "-C", str(PROJECT_ROOT), "branch", "--show-current"],
            capture_output=True, text=True, check=True, timeout=5,
        )
        branch = r.stdout.strip()
    except Exception:
        return None, None
    m = TICKET_RE.search(branch)
    if not m:
        return None, branch
    return m.group(1).upper(), branch


def _close_dim(state, active, dim_name, end_iso, auto):
    """Cierra una dimensión abierta y agrega el intervalo. Devuelve el intervalo.

    En cierres automáticos, una dimensión sin duración real (end <= since) se
    descarta en silencio: no hubo nada que registrar. En cierres manuales
    NUNCA descarta: clampea end=since y marca needs_review.
    """
    dims = active.get("dims") or {}
    d = dims.get(dim_name)
    if not d:
        return None
    start = d["since"]
    start_dt = parse_iso(start)
    end_dt = parse_iso(end_iso)
    dims.pop(dim_name, None)
    needs_review = False
    if end_dt <= start_dt:
        if auto:
            return None
        end_iso = start
        needs_review = True
        minutes = 1
    else:
        minutes = max(1, int(round((end_dt - start_dt).total_seconds() / 60)))
    interval = {
        "ticket": active["ticket"],
        "dimension": dim_name,
        "start": start,
        "end": end_iso,
        "minutes": minutes,
        "source": active.get("source", "manual"),
        "branch": active.get("started_branch"),
        "auto_paused": auto,
        "needs_review": needs_review,
        "synced": False,
        "worklog_id": None,
    }
    state["intervals"].append(interval)
    return interval


def close_active(state, auto_paused=False):
    """Cierra todas las dimensiones abiertas del ticket activo y lo desactiva.
    Devuelve la lista de intervalos generados (puede ser vacía)."""
    active = state.get("active")
    if not active:
        return []
    now = now_iso()
    closed = []
    dims = active.get("dims") or {}
    for name in list(dims.keys()):
        # humano cierra en now (cerrar a mano = estás presente);
        # claude cierra en su último heartbeat visto.
        end = now if name == "humano" else max(dims[name].get("last") or now, dims[name]["since"])
        iv = _close_dim(state, active, name, end, auto_paused)
        if iv:
            closed.append(iv)
    state["active"] = None
    return closed


def touch_activity_markers():
    """Arrancar/reanudar un timer es actividad humana en este proyecto:
    actualiza el heartbeat local y el marker global de último proyecto activo
    (el daemon lo usa para no contar tiempo humano en dos proyectos a la vez)."""
    try:
        HEARTBEAT_FILE.write_text(str(int(datetime.now().timestamp())))
    except Exception:
        pass
    try:
        MARKER_FILE.parent.mkdir(parents=True, exist_ok=True)
        MARKER_FILE.write_text(str(PROJECT_ROOT))
    except Exception:
        pass


def _open_humano(active, since_iso):
    active.setdefault("dims", {})["humano"] = {"since": since_iso, "last": since_iso}


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
    closed = []
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
        "dims": {},
    }
    # start viene de un prompt/comando del usuario → humano presente ya
    _open_humano(state["active"], started)
    save_state(state)
    touch_activity_markers()
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


def cmd_tick(args):
    """Un paso de la máquina de estados. Lo llama el daemon cada 60s con:
    sys_idle_s, front_ok (0|1), proj_ok (0|1), claude_hb_age_s (-1 = sin heartbeat)."""
    if len(args) < 4:
        print(json.dumps({"ok": False, "error": "uso: tick <sys_idle_s> <front_ok> <proj_ok> <claude_hb_age_s>"}))
        return 1
    state = load_state()
    active = state.get("active")
    if not active:
        print(json.dumps({"ok": True, "noop": True}))
        return 0

    sys_idle = float(args[0])
    front_ok = args[1] == "1"
    proj_ok = args[2] == "1"
    hb_age = float(args[3])
    if hb_age < 0:
        hb_age = float("inf")

    now_dt = datetime.now(TZ_LOCAL)
    dims = active.setdefault("dims", {})
    events, closed, evidence = [], [], []

    # --- humano: input reciente + app de la sesión en foco + este proyecto activo
    if front_ok and proj_ok and sys_idle < HUMANO_PAUSE_S:
        last_input = (now_dt - timedelta(seconds=int(sys_idle))).isoformat(timespec="seconds")
        d = dims.get("humano")
        if d:
            d["last"] = max(d["last"], last_input)
        else:
            since = max(last_input, active["started_at"])
            dims["humano"] = {"since": since, "last": max(last_input, since)}
            events.append(f"humano abierto desde {since}")
        evidence.append(dims["humano"]["last"])
    else:
        d = dims.get("humano")
        if d and (now_dt - parse_iso(d["last"])).total_seconds() > HUMANO_PAUSE_S:
            iv = _close_dim(state, active, "humano", d["last"], auto=True)
            events.append(f"humano cerrado en {d['last']}")
            evidence.append(d["last"])
            if iv:
                closed.append(iv)
        elif d:
            evidence.append(d["last"])

    # --- claude: heartbeat de tools fresco
    if hb_age <= CLAUDE_PAUSE_S:
        beat = (now_dt - timedelta(seconds=int(hb_age))).isoformat(timespec="seconds")
        d = dims.get("claude")
        if d:
            d["last"] = max(d["last"], beat)
        else:
            since = max(beat, active["started_at"])
            dims["claude"] = {"since": since, "last": max(beat, since)}
            events.append(f"claude abierto desde {since}")
        evidence.append(dims["claude"]["last"])
    else:
        d = dims.get("claude")
        if d:
            iv = _close_dim(state, active, "claude", d["last"], auto=True)
            events.append(f"claude cerrado en {d['last']}")
            evidence.append(d["last"])
            if iv:
                closed.append(iv)

    # --- última actividad conocida; si murió todo, desactivar el ticket
    if evidence:
        active["last_activity"] = max([active.get("last_activity") or active["started_at"]] + evidence)
    if not dims:
        ref = active.get("last_activity") or active["started_at"]
        if (now_dt - parse_iso(ref)).total_seconds() > HUMANO_PAUSE_S:
            events.append(f"ticket {active['ticket']} desactivado (sin actividad desde {ref})")
            state["active"] = None

    save_state(state)
    print(json.dumps({"ok": True, "events": events, "closed": closed, "active": state.get("active")}, ensure_ascii=False))
    return 0


def cmd_status(args):
    state = load_state()
    now_dt = datetime.now(TZ_LOCAL)
    today = now_dt.date().isoformat()
    per_ticket = {}

    def add(ticket, dim, minutes):
        t = per_ticket.setdefault(ticket, {"humano": 0, "claude": 0, "total": 0})
        t[dim] = t.get(dim, 0) + minutes
        t["total"] += minutes

    for iv in state["intervals"]:
        if iv["start"].startswith(today) or iv["end"].startswith(today):
            add(iv["ticket"], iv.get("dimension", "humano"), iv["minutes"])

    active = state.get("active")
    running = {}
    if active:
        for name, d in (active.get("dims") or {}).items():
            elapsed = int(round((now_dt - parse_iso(d["since"])).total_seconds() / 60))
            running[name] = elapsed
            add(active["ticket"], name, elapsed)

    totals = {"humano": 0, "claude": 0, "total": 0}
    for t in per_ticket.values():
        for k in totals:
            totals[k] += t.get(k, 0)

    print(json.dumps({
        "ok": True,
        "active": active,
        "running_minutes": running,
        "today_by_ticket": per_ticket,
        "today_total": totals,
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
    started = now_iso()
    state["active"] = {
        "ticket": last["ticket"],
        "started_at": started,
        "started_branch": branch,
        "source": "resume",
        "dims": {},
    }
    # resume viene de un prompt del usuario → humano presente
    _open_humano(state["active"], started)
    save_state(state)
    touch_activity_markers()
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
    "tick": cmd_tick,
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
