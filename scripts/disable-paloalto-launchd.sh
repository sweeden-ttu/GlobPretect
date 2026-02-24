#!/bin/bash
# disable-paloalto-launchd.sh
# Unload the three Palo Alto Networks / GlobalProtect launchd jobs (mirroring
# enable-paloalto-launchd.sh but with launchctl bootout) and reset BTM so they
# stay disabled. Assume this script is run as root.
#
# Usage: run as root (e.g. ./disable-paloalto-launchd.sh when already root)

DAEMON_PLIST="/Library/LaunchDaemons/com.paloaltonetworks.gp.pangpsd.plist"
AGENT_PANGPS="/Library/LaunchAgents/com.paloaltonetworks.gp.pangps.plist"
AGENT_PANGPA="/Library/LaunchAgents/com.paloaltonetworks.gp.pangpa.plist"

GUI_DOMAIN="gui/$(id -u)"

echo "Disabling Palo Alto Networks (3 items) from running in background..."

# 1. System daemon — same domain + plist path as enable script (bootstrap → bootout)
if [ -f "$DAEMON_PLIST" ]; then
	if launchctl print system/com.paloaltonetworks.gp.pangpsd &>/dev/null; then
		launchctl bootout system "$DAEMON_PLIST" && echo "  Daemon com.paloaltonetworks.gp.pangpsd unloaded."
	else
		echo "  Daemon com.paloaltonetworks.gp.pangpsd not loaded."
	fi
else
	echo "  Daemon plist not found: $DAEMON_PLIST"
fi

# 2. User agents — same domain + plist path as enable script
if [ -f "$AGENT_PANGPS" ]; then
	if launchctl print "$GUI_DOMAIN/com.paloaltonetworks.gp.pangps" &>/dev/null; then
		launchctl bootout "$GUI_DOMAIN" "$AGENT_PANGPS" && echo "  Agent com.paloaltonetworks.gp.pangps unloaded."
	else
		echo "  Agent com.paloaltonetworks.gp.pangps not loaded."
	fi
else
	echo "  Agent plist not found: $AGENT_PANGPS"
fi

if [ -f "$AGENT_PANGPA" ]; then
	if launchctl print "$GUI_DOMAIN/com.paloaltonetworks.gp.pangpa" &>/dev/null; then
		launchctl bootout "$GUI_DOMAIN" "$AGENT_PANGPA" && echo "  Agent com.paloaltonetworks.gp.pangpa unloaded."
	else
		echo "  Agent com.paloaltonetworks.gp.pangpa not loaded."
	fi
else
	echo "  Agent plist not found: $AGENT_PANGPA"
fi

# 3. Kill running PanGPS so VPN actually stops
if pgrep -f "PanGPS" >/dev/null 2>&1; then
	pkill -f "PanGPS" 2>/dev/null && echo "  PanGPS processes stopped." || true
else
	echo "  No PanGPS processes running."
fi

# 4. sfltool resetbtm — reset all login/background items so Palo Alto (and others) stay disabled
#    WARNING: This clears ALL "Open at Login" and "Allow in the Background" items system-wide.
echo "  Running sfltool resetbtm to clear BTM so Palo Alto items stay disabled..."
sfltool resetbtm 2>/dev/null && echo "  BTM reset. Restart recommended." || echo "  sfltool resetbtm failed or not available."

echo "Done. To re-enable VPN, run enable-paloalto-launchd.sh as root, then turn ON the three Palo Alto items in System Settings > General > Login Items > Allow in the Background."
