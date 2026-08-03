#!/usr/bin/env python3
"""Sube a Jira los intervalos de tiempo pendientes (synced:false).

Es el plan B de cuando el MCP de Atlassian no levanta: hace lo mismo que haría
el MCP —un worklog por intervalo, comment [humano]/[claude]— pero por la API REST
directa. Lee las credenciales de ~/.config/claude/jira.env (JIRA_URL,
JIRA_EMAIL, JIRA_API_TOKEN); el token nunca se pasa por línea de comandos.

Uso:  python3 .claude/tiempo/sync-jira.py
"""
import base64
import json
import os
import ssl
import subprocess
import sys
import urllib.request
from pathlib import Path

HERE = Path(__file__).resolve().parent

# El Python de macOS no siempre encuentra el bundle de CAs del sistema; usamos
# el de certifi si está, así el TLS a Jira verifica bien.
try:
    import certifi
    SSL_CTX = ssl.create_default_context(cafile=certifi.where())
except Exception:
    SSL_CTX = ssl.create_default_context()


def cargar_env():
    env = {}
    ruta = Path.home() / ".config/claude/jira.env"
    if ruta.exists():
        for linea in ruta.read_text().splitlines():
            linea = linea.strip()
            if not linea or linea.startswith("#") or "=" not in linea:
                continue
            k, v = linea.split("=", 1)
            env[k.strip()] = v.strip().strip('"').strip("'")
    for k in ("JIRA_URL", "JIRA_EMAIL", "JIRA_API_TOKEN"):
        env.setdefault(k, os.environ.get(k, ""))
    faltan = [k for k in ("JIRA_URL", "JIRA_EMAIL", "JIRA_API_TOKEN") if not env.get(k)]
    if faltan:
        sys.exit(f"Faltan credenciales: {', '.join(faltan)} (revisá ~/.config/claude/jira.env)")
    return env


def started_jira(iso: str) -> str:
    # "2026-07-21T22:37:11-03:00" -> "2026-07-21T22:37:11.000-0300"
    fecha, offset = iso[:19], iso[19:]
    return f"{fecha}.000{offset.replace(':', '')}"


def pendientes():
    out = subprocess.run(
        [sys.executable, str(HERE / "timer.py"), "pending-sync"],
        capture_output=True, text=True, check=True,
    ).stdout
    return json.loads(out).get("pending", [])


def subir_worklog(env, iv):
    url = f"{env['JIRA_URL'].rstrip('/')}/rest/api/3/issue/{iv['ticket']}/worklog"
    cuerpo = {
        "timeSpentSeconds": max(60, iv["minutes"] * 60),
        "started": started_jira(iv["start"]),
        "comment": {
            "type": "doc", "version": 1,
            "content": [{"type": "paragraph",
                         "content": [{"type": "text", "text": f"[{iv['dimension']}]"}]}],
        },
    }
    auth = base64.b64encode(f"{env['JIRA_EMAIL']}:{env['JIRA_API_TOKEN']}".encode()).decode()
    req = urllib.request.Request(
        url, data=json.dumps(cuerpo).encode(),
        headers={"Authorization": f"Basic {auth}", "Content-Type": "application/json",
                 "Accept": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=30, context=SSL_CTX) as r:
        return json.load(r)["id"]


def main():
    env = cargar_env()
    ivs = pendientes()
    if not ivs:
        print("No hay intervalos pendientes. Todo al día.")
        return
    print(f"{len(ivs)} intervalos para subir a {env['JIRA_URL']}\n")
    ok = 0
    for iv in ivs:
        etiqueta = f"{iv['ticket']} [{iv['dimension']}] {iv['minutes']}m ({iv['start'][:16]})"
        try:
            wid = subir_worklog(env, iv)
            subprocess.run([sys.executable, str(HERE / "timer.py"),
                            "mark-synced", str(iv["idx"]), str(wid)], check=True)
            print(f"  ✓ {etiqueta}  -> worklog {wid}")
            ok += 1
        except Exception as e:
            detalle = ""
            if hasattr(e, "read"):
                try:
                    detalle = " · " + e.read().decode()[:200]
                except Exception:
                    pass
            print(f"  ✗ {etiqueta}  FALLÓ: {e}{detalle}")
    print(f"\nListo: {ok}/{len(ivs)} subidos.")


if __name__ == "__main__":
    main()
