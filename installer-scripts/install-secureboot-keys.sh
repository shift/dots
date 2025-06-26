#!/usr/bin/env bash
# Install secure boot keys automatically
# Requires system to be in setup mode

set -euo pipefail

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

# Configuration
SECUREBOOT_DIR="/secureboot"
SBCTL_DIR="/var/lib/sbctl"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log "ERROR: This script must be run as root"
    exit 1
fi

# Check if secure boot keys directory exists
if [ ! -d "$SECUREBOOT_DIR" ]; then
    log "ERROR: Secure boot keys directory not found: $SECUREBOOT_DIR"
    exit 1
fi

# Check if we have EFI support
if [ ! -d /sys/firmware/efi ]; then
    log "ERROR: System does not have EFI firmware support"
    exit 1
fi

# Ensure efivars is mounted
if [ ! -d /sys/firmware/efi/efivars ]; then
    log "INFO: Mounting efivars filesystem"
    mount -t efivarfs efivarfs /sys/firmware/efi/efivars || {
        log "ERROR: Failed to mount efivars"
        exit 1
    }
fi

# Check if system is in setup mode first
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
if ! "$SCRIPT_DIR/detect-setup-mode.sh"; then
    log "ERROR: System is not in Secure Boot setup mode. Please enable setup mode in BIOS/UEFI settings."
    exit 1
fi

log "INFO: System is in setup mode, proceeding with key installation"

# Create sbctl directory if it doesn't exist
mkdir -p "$SBCTL_DIR"

# Check if keys are already installed
if sbctl status 2>/dev/null | grep -q "Secure Boot.*Enabled"; then
    log "INFO: Secure Boot is already configured and enabled"
    exit 0
fi

# Initialize sbctl if not already done
if [ ! -f "$SBCTL_DIR/keys/db/db.pem" ]; then
    log "INFO: Creating new Secure Boot keys with sbctl"
    if ! sbctl create-keys; then
        log "ERROR: Failed to create Secure Boot keys"
        exit 1
    fi
else
    log "INFO: Using existing Secure Boot keys from $SBCTL_DIR"
fi

# Copy keys from the secure boot directory if they exist and are different
if [ -f "$SECUREBOOT_DIR/keys/db/db.pem" ]; then
    log "INFO: Using pre-configured Secure Boot keys from $SECUREBOOT_DIR"
    
    # Backup existing keys if they exist
    if [ -d "$SBCTL_DIR/keys" ]; then
        log "INFO: Backing up existing keys"
        mv "$SBCTL_DIR/keys" "$SBCTL_DIR/keys.backup.$(date +%s)" || true
    fi
    
    # Copy the pre-configured keys
    cp -r "$SECUREBOOT_DIR/keys" "$SBCTL_DIR/"
    cp -r "$SECUREBOOT_DIR/bundles" "$SBCTL_DIR/" 2>/dev/null || true
fi

# Enroll the keys
log "INFO: Enrolling Secure Boot keys"
if ! sbctl enroll-keys --yes-this-might-brick-my-machine; then
    log "ERROR: Failed to enroll Secure Boot keys"
    exit 1
fi

# Verify the installation
log "INFO: Verifying Secure Boot key installation"
sbctl status

log "INFO: Secure Boot keys have been successfully installed"
log "WARNING: Please reboot the system and verify Secure Boot is working properly"

exit 0