#!/usr/bin/env bash
# Automated NixOS installation using nixos-anywhere
# This script runs after secure boot keys are installed

set -euo pipefail

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

# Configuration
REPO_DIR="/repo"
FLAKE_CONFIG="$REPO_DIR#shulkerbox"
TARGET_HOST="localhost"
SSH_KEY_PATH="/ssh_keys/ssh_host_ed25519_key"

# Parse command line arguments
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    -h, --help          Show this help message
    -t, --target HOST   Target hostname or IP (default: localhost)
    -f, --flake FLAKE   Flake configuration to use (default: $FLAKE_CONFIG)
    -k, --ssh-key PATH  SSH key path (default: $SSH_KEY_PATH)
    --dry-run           Show what would be done without executing
    --debug             Enable debug output

Examples:
    $0                                  # Install on localhost
    $0 -t 192.168.1.100                # Install on remote host
    $0 -f /repo#shulkerbox-server      # Use different flake config
EOF
}

# Default values
DRY_RUN=false
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
        -k|--ssh-key)
            SSH_KEY_PATH="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --debug)
            DEBUG=true
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

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log "ERROR: This script must be run as root"
    exit 1
fi

# Check if required directories exist
if [ ! -d "$REPO_DIR" ]; then
    log "ERROR: Repository directory not found: $REPO_DIR"
    exit 1
fi

# Check if nixos-anywhere is available
if ! command -v nixos-anywhere >/dev/null 2>&1; then
    log "ERROR: nixos-anywhere not found in PATH"
    exit 1
fi

# Check if disko is available  
if ! command -v disko >/dev/null 2>&1; then
    log "ERROR: disko not found in PATH"
    exit 1
fi

log "INFO: Starting automated NixOS installation"
log "INFO: Target: $TARGET_HOST"
log "INFO: Flake: $FLAKE_CONFIG"

if $DRY_RUN; then
    log "INFO: DRY RUN MODE - Commands that would be executed:"
    echo "nixos-anywhere --flake $FLAKE_CONFIG $TARGET_HOST"
    exit 0
fi

# Change to repository directory
cd "$REPO_DIR"

# Pre-installation checks
log "INFO: Running pre-installation checks"

# Check if flake configuration exists
if ! nix flake show "$FLAKE_CONFIG" >/dev/null 2>&1; then
    log "ERROR: Flake configuration not found or invalid: $FLAKE_CONFIG"
    exit 1
fi

# For localhost installation, we need to ensure network is configured
if [ "$TARGET_HOST" = "localhost" ]; then
    log "INFO: Configuring network for localhost installation"
    
    # Check if network is available
    if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        log "WARNING: Network connectivity test failed, attempting to configure network"
        
        # Try to bring up network interfaces
        if command -v networkctl >/dev/null 2>&1; then
            networkctl up || true
        fi
        
        if command -v nmcli >/dev/null 2>&1; then
            nmcli networking on || true
        fi
        
        # Wait a bit for network to come up
        sleep 5
        
        # Test again
        if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
            log "ERROR: Network connectivity is required for installation"
            exit 1
        fi
    fi
fi

# Run the installation
log "INFO: Starting nixos-anywhere installation"
log "INFO: This may take a while..."

# Build the nixos-anywhere command
NIXOS_ANYWHERE_CMD=(
    nixos-anywhere
    --flake "$FLAKE_CONFIG"
)

# Add SSH key if it exists and we're not installing on localhost
if [ "$TARGET_HOST" != "localhost" ] && [ -f "$SSH_KEY_PATH" ]; then
    NIXOS_ANYWHERE_CMD+=(--ssh-key "$SSH_KEY_PATH")
fi

# Add the target
NIXOS_ANYWHERE_CMD+=("$TARGET_HOST")

# Execute the installation
log "INFO: Executing: ${NIXOS_ANYWHERE_CMD[*]}"
if "${NIXOS_ANYWHERE_CMD[@]}"; then
    log "INFO: NixOS installation completed successfully!"
    log "INFO: Please reboot the system to complete the installation"
else
    log "ERROR: NixOS installation failed"
    exit 1
fi

exit 0