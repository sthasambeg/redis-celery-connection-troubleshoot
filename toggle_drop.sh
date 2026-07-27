#!/usr/bin/env bash
set -e

CONTAINER=${1:?"Error: Container name/ID required. Usage: $0 <container> [on|off|status] [interface]"}
ACTION=${2:-status}
IFACE=${3:-eth0}

case "$ACTION" in
on)
	echo "--> Enabling 100% packet loss on '$CONTAINER' ($IFACE)..."
	# Delete any existing qdisc rule first to avoid 'File exists' errors
	docker exec -u 0 "$CONTAINER" tc qdisc del dev "$IFACE" root 2>/dev/null || true
	docker exec -u 0 "$CONTAINER" tc qdisc add dev "$IFACE" root netem loss 100%
	echo "--> ACTIVE: Socket drop enabled. Network connections will hang/timeout."
	;;

off)
	echo "--> Disabling packet loss on '$CONTAINER' ($IFACE)..."
	docker exec -u 0 "$CONTAINER" tc qdisc del dev "$IFACE" root 2>/dev/null || true
	echo "--> RESTORED: Network traffic returned to normal."
	;;

status)
	echo "--> Current tc status for '$CONTAINER' ($IFACE):"
	docker exec -u 0 "$CONTAINER" tc qdisc show dev "$IFACE"
	;;

*)
	echo "Error: Invalid action '$ACTION'. Supported actions: on, off, status"
	exit 1
	;;
esac
