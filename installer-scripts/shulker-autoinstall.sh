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
    install         Automated installation with smart detection (default)
                   - Checks TPM2 availability
                   - Detects existing partitions
                   - Guides user through issues
                   - Auto-installs when safe
    setup-mode      Check if system is in setup mode
    install-keys    Install secure boot keys only
    install-nixos   Install NixOS only
    status          Show installation status and system info

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
    $0                              # Smart automated installation
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

# Function to check TPM2 availability using available tools
check_tpm2() {
    log "INFO: Checking TPM2 availability"
    
    # Check if TPM device exists
    if [ -e /dev/tpm0 ] || [ -e /dev/tpmrm0 ]; then
        log "INFO: TPM device found"
        
        # Try to get TPM info using tpm2-tools if available
        if command -v tpm2_getcap >/dev/null 2>&1; then
            if tpm2_getcap properties-fixed >/dev/null 2>&1; then
                log "INFO: TPM2 is functional"
                return 0
            fi
        fi
        
        # Fallback: check dmesg for TPM
        if dmesg | grep -i "tpm.*2\.0" >/dev/null 2>&1; then
            log "INFO: TPM2 detected in kernel messages"
            return 0
        fi
    fi
    
    log "WARNING: No functional TPM2 detected"
    return 1
}

# Function to check for existing partitions
check_existing_partitions() {
    log "INFO: Checking for existing partitions"
    
    # Get all block devices with partitions
    local has_partitions=false
    
    for device in /dev/sd* /dev/nvme* /dev/vd*; do
        if [ -b "$device" ] && [[ ! "$device" =~ [0-9]$ ]]; then
            # Check if this device has partitions
            if lsblk "$device" --output NAME --noheadings | grep -q "├\|└"; then
                log "INFO: Found existing partitions on $device"
                has_partitions=true
            fi
        fi
    done 2>/dev/null
    
    if $has_partitions; then
        return 0
    else
        log "INFO: No existing partitions found"
        return 1
    fi
}

# Function to provide interactive guidance using gum
interactive_guidance() {
    local situation="$1"
    
    if ! command -v gum >/dev/null 2>&1; then
        log "WARNING: gum not available for interactive guidance, falling back to text prompts"
        echo "Situation: $situation"
        echo "Please resolve the issue manually and run the installer again."
        return 1
    fi
    
    case "$situation" in
        "existing_partitions")
            gum style --foreground 212 --border double --padding "1 2" \
                "Existing Partitions Detected" \
                "" \
                "The system has existing partitions. What would you like to do?"
            
            choice=$(gum choose "View partitions and continue manually" "Backup and wipe all partitions" "Cancel installation")
            
            case "$choice" in
                "View partitions and continue manually")
                    gum style --foreground 33 "Current partition layout:"
                    lsblk
                    gum style --foreground 33 \
                        "Please manually run 'disko' to partition your disks," \
                        "then run 'shulker-install install-nixos' to continue."
                    return 1
                    ;;
                "Backup and wipe all partitions")
                    gum confirm "⚠️  This will PERMANENTLY DELETE all data. Are you sure?" || return 1
                    gum confirm "⚠️  LAST WARNING: All data will be lost. Continue?" || return 1
                    return 0
                    ;;
                *)
                    gum style --foreground 196 "Installation cancelled by user"
                    return 1
                    ;;
            esac
            ;;
            
        "no_setup_mode")
            gum style --foreground 212 --border double --padding "1 2" \
                "Secure Boot Not in Setup Mode" \
                "" \
                "The system is not in Secure Boot setup mode." \
                "This is required for automatic key installation."
            
            choice=$(gum choose "Enter BIOS/UEFI to enable setup mode" "Skip Secure Boot setup" "Cancel installation")
            
            case "$choice" in
                "Enter BIOS/UEFI to enable setup mode")
                    gum style --foreground 33 \
                        "Please:" \
                        "1. Reboot and enter BIOS/UEFI settings" \
                        "2. Find Secure Boot settings" \
                        "3. Clear/Delete all Secure Boot keys" \
                        "4. Enable Setup Mode" \
                        "5. Boot back into the installer" \
                        "" \
                        "Then run 'shulker-install' again."
                    return 1
                    ;;
                "Skip Secure Boot setup")
                    gum style --foreground 33 "Continuing without Secure Boot setup..."
                    return 0
                    ;;
                *)
                    gum style --foreground 196 "Installation cancelled by user"
                    return 1
                    ;;
            esac
            ;;
            
        "no_tpm")
            gum style --foreground 212 --border double --padding "1 2" \
                "No TPM2 Detected" \
                "" \
                "TPM2 is recommended for enhanced security."
                
            choice=$(gum choose "Continue without TPM2" "Check BIOS/UEFI for TPM settings" "Cancel installation")
            
            case "$choice" in
                "Continue without TPM2")
                    gum style --foreground 33 "Continuing without TPM2..."
                    return 0
                    ;;
                "Check BIOS/UEFI for TPM settings")
                    gum style --foreground 33 \
                        "Please:" \
                        "1. Reboot and enter BIOS/UEFI settings" \
                        "2. Look for TPM/Security settings" \
                        "3. Enable TPM if available" \
                        "4. Boot back into the installer" \
                        "" \
                        "Then run 'shulker-install' again."
                    return 1
                    ;;
                *)
                    gum style --foreground 196 "Installation cancelled by user"
                    return 1
                    ;;
            esac
            ;;
    esac
}

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
    
    # Check TPM2 status
    echo
    echo "=== TPM2 Status ==="
    if check_tpm2 >/dev/null 2>&1; then
        echo "✓ TPM2 detected and functional"
    else
        echo "✗ No functional TPM2 detected"
    fi
    
    # Check partition status
    echo
    echo "=== Disk Status ==="
    if check_existing_partitions >/dev/null 2>&1; then
        echo "⚠ Existing partitions detected:"
        lsblk --output NAME,SIZE,TYPE,MOUNTPOINT | head -20
    else
        echo "✓ No existing partitions found"
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
    for tool in nixos-anywhere disko sbctl gum tpm2_getcap; do
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
        log "INFO: Starting automated installation with smart detection"
        
        # Step 1: Check TPM2 availability
        if ! check_tpm2; then
            if ! interactive_guidance "no_tpm"; then
                exit 1
            fi
        fi
        
        # Step 2: Check for existing partitions
        if check_existing_partitions; then
            log "WARNING: Existing partitions detected"
            if ! interactive_guidance "existing_partitions"; then
                exit 1
            fi
        fi
        
        # Step 3: Check setup mode unless skipping secure boot
        if ! $SKIP_SECUREBOOT; then
            if ! check_setup_mode; then
                log "WARNING: System is not in Secure Boot setup mode"
                if ! $FORCE; then
                    if ! interactive_guidance "no_setup_mode"; then
                        # User chose to skip secure boot
                        SKIP_SECUREBOOT=true
                    fi
                else
                    log "INFO: Forcing installation despite setup mode"
                fi
            fi
            
            # Install secure boot keys if not skipping
            if ! $SKIP_SECUREBOOT; then
                if ! install_secure_boot_keys; then
                    log "ERROR: Failed to install Secure Boot keys"
                    exit 1
                fi
            fi
        else
            log "INFO: Skipping Secure Boot key installation"
        fi
        
        # Step 4: Install NixOS unless skipping
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