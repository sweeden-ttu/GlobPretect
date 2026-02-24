#!/bin/bash
# enable-paloalto-launchd.sh
# Load the three Palo Alto Networks / GlobalProtect launchd jobs so they run in
# background and load at startup. Uses launchctl (not sfltool — sfltool has no
# command to enable specific BTM items).
#
# Prerequisite: In System Settings > General > Login Items > Allow in the
# Background, the three Palo Alto Networks items must be turned ON at least once.
# Otherwise BTM policy may block launchd from loading them.
#
# Usage: ./enable-paloalto-launchd.sh
#        sudo ./enable-paloalto-launchd.sh  (needed for the daemon)

set -e

DAEMON_PLIST="/Library/LaunchDaemons/com.paloaltonetworks.gp.pangpsd.plist"
AGENT_PANGPS="/Library/LaunchAgents/com.paloaltonetworks.gp.pangps.plist"
AGENT_PANGPA="/Library/LaunchAgents/com.paloaltonetworks.gp.pangpa.plist"

echo "Enabling Palo Alto Networks (3 items) to run in background and load at startup..."

# 1. System daemon (requires root)
if [ -f "$DAEMON_PLIST" ]; then
	if launchctl print system/com.paloaltonetworks.gp.pangpsd &>/dev/null; then
		echo "  Daemon com.paloaltonetworks.gp.pangpsd already loaded."
	else
		if [ "$(id -u)" -eq 0 ]; then
			launchctl bootstrap system "$DAEMON_PLIST" && echo "  Daemon com.paloaltonetworks.gp.pangpsd loaded."
		else
			echo "  Daemon requires root. Run: sudo launchctl bootstrap system $DAEMON_PLIST"
		fi
	fi
else
	echo "  Daemon plist not found: $DAEMON_PLIST"
fi

# 2. User agents (GUI session)
GUI_DOMAIN="gui/$(id -u)"

if [ -f "$AGENT_PANGPS" ]; then
	if launchctl print "$GUI_DOMAIN/com.paloaltonetworks.gp.pangps" &>/dev/null; then
		echo "  Agent com.paloaltonetworks.gp.pangps already loaded."
	else
		launchctl bootstrap "$GUI_DOMAIN" "$AGENT_PANGPS" && echo "  Agent com.paloaltonetworks.gp.pangps loaded."
	fi
else
	echo "  Agent plist not found: $AGENT_PANGPS"
fi

if [ -f "$AGENT_PANGPA" ]; then
	if launchctl print "$GUI_DOMAIN/com.paloaltonetworks.gp.pangpa" &>/dev/null; then
		echo "  Agent com.paloaltonetworks.gp.pangpa already loaded."
	else
		launchctl bootstrap "$GUI_DOMAIN" "$AGENT_PANGPA" && echo "  Agent com.paloaltonetworks.gp.pangpa loaded."
	fi
else
	echo "  Agent plist not found: $AGENT_PANGPA"
fi

echo "Done. If you see BTM policy errors, enable the three Palo Alto items in System Settings > General > Login Items > Allow in the Background, then run this script again."
