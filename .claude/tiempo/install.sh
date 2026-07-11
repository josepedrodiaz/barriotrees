#!/usr/bin/env bash
# Instala (o reinstala) el daemon de auto-pausa en launchd.
# El label y los paths se derivan del proyecto → no hay plist hardcodeado.
# Uso: ./install.sh [install|uninstall|status|logs]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# slug estable y legible: si el root es un nombre genérico (wp-content, public,
# etc, típico de LocalWP), sube hasta el primer ancestro con nombre propio.
GENERIC=" wp-content public htdocs www app httpdocs web "
_d="$PROJECT_ROOT"; _name="$(basename "$_d")"
while [[ "$GENERIC" == *" $_name "* && "$_d" != "/" ]]; do
  _d="$(dirname "$_d")"; _name="$(basename "$_d")"
done
SLUG="$(echo "$_name" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' '-' | sed 's/-\{1,\}/-/g; s/^-//; s/-$//')"
LABEL="com.claude-tiempo.$SLUG"
PLIST_DST="$HOME/Library/LaunchAgents/$LABEL.plist"

gen_plist() {
  cat > "$PLIST_DST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/bin/python3</string>
    <string>$SCRIPT_DIR/daemon.py</string>
  </array>
  <key>StartInterval</key>
  <integer>60</integer>
  <key>RunAtLoad</key>
  <true/>
  <key>StandardOutPath</key>
  <string>$SCRIPT_DIR/daemon.out</string>
  <key>StandardErrorPath</key>
  <string>$SCRIPT_DIR/daemon.err</string>
</dict>
</plist>
PLIST
}

cmd="${1:-install}"

case "$cmd" in
  install)
    mkdir -p "$HOME/Library/LaunchAgents"
    gen_plist
    launchctl unload "$PLIST_DST" 2>/dev/null || true
    launchctl load "$PLIST_DST"
    echo "✓ Daemon instalado y corriendo (cada 60s)"
    echo "  label: $LABEL"
    echo "  plist: $PLIST_DST"
    echo "  logs:  $SCRIPT_DIR/daemon.log"
    ;;
  uninstall)
    launchctl unload "$PLIST_DST" 2>/dev/null || true
    rm -f "$PLIST_DST"
    echo "✓ Daemon desinstalado ($LABEL)"
    ;;
  status)
    if launchctl list | grep -q "$LABEL"; then
      echo "✓ Daemon corriendo"
      launchctl list | grep "$LABEL"
    else
      echo "✗ Daemon NO está corriendo. Ejecutá: ./install.sh install"
    fi
    ;;
  logs)
    tail -50 "$SCRIPT_DIR/daemon.log" 2>/dev/null || echo "(sin logs todavía)"
    ;;
  *)
    echo "Uso: $0 [install|uninstall|status|logs]"; exit 1 ;;
esac
