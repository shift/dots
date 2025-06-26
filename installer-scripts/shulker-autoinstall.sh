#!/usr/bin/env bash
# Main orchestration script for shulker-installer automation
# This script coordinates the entire installation process

set -euo pipefail

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

# Configuration
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
INSTALLER_LOG="/var/log/shulker-installer.log"

# Create log directory
mkdir -p "$(dirname "$INSTALLER_LOG")"

# Redirect all output to log file as well as console
exec > >(tee -a "$INSTALLER_LOG")
exec 2>&1

# Parse command line arguments
show_help() {
    cat << EOF
Shulker Installer - Automated Secure Boot & NixOS Installation

Usage: $0 [OPTIONS] [COMMAND]

Commands:
    install         Full automated installation (default)
    setup-mode      Check if system is in setup mode
    install-keys    Install secure boot keys only
    install-nixos   Install NixOS only
    status          Show installation status

Options:
    -h, --help          Show this help message
    -t, --target HOST   Target hostname or IP for NixOS installation
    -f, --flake FLAKE   Flake configuration to use
    --skip-secureboot   Skip secure boot key installation
    --skip-nixos        Skip NixOS installation
    --dry-run           Show what would be done without executing
    --force             Force installation even if not in setup mode
    --debug             Enable debug output

Examples:
    $0                              # Full automated installation
    $0 install-keys                 # Install secure boot keys only
    $0 install-nixos -t 192.168.1.100  # Install NixOS on remote host
    $0 --skip-secureboot install    # Install NixOS without secure boot
EOF
}

# Default values
COMMAND="install"
TARGET_HOST="localhost"
FLAKE_CONFIG="/repo#shulkerbox"
SKIP_SECUREBOOT=false
SKIP_NIXOS=false
DRY_RUN=false
FORCE=false
DEBUG=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -t|--target)
            TARGET_HOST="$2"
            shift 2
            ;;
        -f|--flake)
            FLAKE_CONFIG="$2"
            shift 2
            ;;
        --skip-secureboot)
            SKIP_SECUREBOOT=true
            shift
            ;;
        --skip-nixos)
            SKIP_NIXOS=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --debug)
            DEBUG=true
            shift
            ;;
        install|setup-mode|install-keys|install-nixos|status)
            COMMAND="$1"
            shift
            ;;
        *)
            log "ERROR: Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Enable debug mode if requested
if $DEBUG; then
    set -x
fi

# Check if running as root (except for status command)
if [ "$COMMAND" != "status" ] && [ "$EUID" -ne 0 ]; then
    log "ERROR: This script must be run as root (except for 'status' command)"
    exit 1
fi

# Function to check setup mode
check_setup_mode() {
    log "INFO: Checking if system is in Secure Boot setup mode"
    if "$SCRIPT_DIR/detect-setup-mode.sh"; then
        return 0
    else
        return 1
    fi
}

# Function to install secure boot keys
install_secure_boot_keys() {
    log "INFO: Installing Secure Boot keys"
    if $DRY_RUN; then
        log "INFO: DRY RUN - Would install secure boot keys"
        return 0
    fi
    
    if "$SCRIPT_DIR/install-secureboot-keys.sh"; then
        log "INFO: Secure Boot keys installed successfully"
        return 0
    else
        log "ERROR: Failed to install Secure Boot keys"
        return 1
    fi
}

# Function to install NixOS
install_nixos() {
    log "INFO: Installing NixOS"
    local cmd_args=()
    
    if $DRY_RUN; then
        cmd_args+=(--dry-run)
    fi
    
    if $DEBUG; then
        cmd_args+=(--debug)
    fi
    
    cmd_args+=(-t "$TARGET_HOST" -f "$FLAKE_CONFIG")
    
    if "$SCRIPT_DIR/auto-install-nixos.sh" "${cmd_args[@]}"; then
        log "INFO: NixOS installation completed successfully"
        return 0
    else
        log "ERROR: NixOS installation failed"
        return 1
    fi
}

# Function to show status
show_status() {
    echo "=== Shulker Installer Status ==="
    echo
    
    # Check EFI support
    if [ -d /sys/firmware/efi ]; then
        echo "✓ EFI firmware support detected"
    else
        echo "✗ No EFI firmware support"
    fi
    
    # Check setup mode
    if check_setup_mode >/dev/null 2>&1; then
        echo "✓ System is in Secure Boot setup mode"
    else
        echo "✗ System is NOT in Secure Boot setup mode"
    fi
    
    # Check secure boot status
    if command -v sbctl >/dev/null 2>&1; then
        echo
        echo "=== Secure Boot Status ==="
        sbctl status 2>/dev/null || echo "Unable to determine Secure Boot status"
    fi
    
    # Check if required directories exist
    echo
    echo "=== Resource Availability ==="
    if [ -d /repo ]; then
        echo "✓ Repository available at /repo"
    else
        echo "✗ Repository not found at /repo"
    fi
    
    if [ -d /secureboot ]; then
        echo "✓ Secure boot keys available at /secureboot"
    else
        echo "✗ Secure boot keys not found at /secureboot"
    fi
    
    if [ -d /ssh_keys ]; then
        echo "✓ SSH keys available at /ssh_keys"
    else
        echo "✗ SSH keys not found at /ssh_keys"
    fi
    
    # Check required tools
    echo
    echo "=== Required Tools ==="
    for tool in nixos-anywhere disko sbctl; do
        if command -v "$tool" >/dev/null 2>&1; then
            echo "✓ $tool available"
        else
            echo "✗ $tool not found"
        fi
    done
}

# Main execution
log "INFO: Starting Shulker Installer - Command: $COMMAND"

case "$COMMAND" in
    "status")
        show_status
        ;;
        
    "setup-mode")
        if check_setup_mode; then
            log "INFO: System is in Secure Boot setup mode"
            exit 0
        else
            log "INFO: System is NOT in Secure Boot setup mode"
            exit 1
        fi
        ;;
        
    "install-keys")
        if ! $FORCE && ! check_setup_mode; then
            log "ERROR: System is not in setup mode. Use --force to override."
            exit 1
        fi
        install_secure_boot_keys
        ;;
        
    "install-nixos")
        install_nixos
        ;;
        
    "install")
        log "INFO: Starting full automated installation"
        
        # Check setup mode unless skipping secure boot
        if ! $SKIP_SECUREBOOT; then
            if ! $FORCE && ! check_setup_mode; then
                log "ERROR: System is not in Secure Boot setup mode."
                log "INFO: Please enable setup mode in BIOS/UEFI settings or use --skip-secureboot"
                exit 1
            fi
            
            # Install secure boot keys
            if ! install_secure_boot_keys; then
                log "ERROR: Failed to install Secure Boot keys"
                exit 1
            fi
        else
            log "INFO: Skipping Secure Boot key installation"
        fi
        
        # Install NixOS unless skipping
        if ! $SKIP_NIXOS; then
            if ! install_nixos; then
                log "ERROR: Failed to install NixOS"
                exit 1
            fi
        else
            log "INFO: Skipping NixOS installation"
        fi
        
        log "INFO: Installation completed successfully!"
        if ! $SKIP_NIXOS; then
            log "INFO: Please reboot the system to complete the installation"
        fi
        ;;
        
    *)
        log "ERROR: Unknown command: $COMMAND"
        show_help
        exit 1
        ;;
esac

exit 0