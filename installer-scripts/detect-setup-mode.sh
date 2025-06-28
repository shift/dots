#!/usr/bin/env bash
# Detect if the system is in Secure Boot setup mode
# Returns 0 if in setup mode, 1 if not, 2 if unable to determine

set -euo pipefail

# Function to log messages
log() {
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

# Check if we have EFI support
if [ ! -d /sys/firmware/efi ]; then
	log "ERROR: System does not have EFI firmware support"
	exit 2
fi

# Check if efivars are mounted
if [ ! -d /sys/firmware/efi/efivars ]; then
	log "WARNING: EFI variables not accessible, attempting to mount efivars"
	if ! mount -t efivarfs efivarfs /sys/firmware/efi/efivars 2>/dev/null; then
		log "ERROR: Unable to mount efivars filesystem"
		exit 2
	fi
fi

# Check for SetupMode variable
SETUP_MODE_VAR="/sys/firmware/efi/efivars/SetupMode-8be4df61-93ca-11d2-aa0d-00e098032b8c"

if [ ! -f "$SETUP_MODE_VAR" ]; then
	log "ERROR: SetupMode EFI variable not found"
	exit 2
fi

# Read the SetupMode value (skip first 4 bytes which are attributes)
SETUP_MODE=$(xxd -s 4 -l 1 -p "$SETUP_MODE_VAR" 2>/dev/null | tr '[:lower:]' '[:upper:]')

if [ -z "$SETUP_MODE" ]; then
	log "ERROR: Unable to read SetupMode value"
	exit 2
fi

case "$SETUP_MODE" in
"01")
	log "INFO: System is in Secure Boot Setup Mode"
	exit 0
	;;
"00")
	log "INFO: System is NOT in Secure Boot Setup Mode"
	exit 1
	;;
*)
	log "ERROR: Unknown SetupMode value: $SETUP_MODE"
	exit 2
	;;
esac
