#!/usr/bin/env bash
# Validation script to test shulker-installer automation

set -euo pipefail

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

log "INFO: Starting shulker-installer validation tests"

# Test 1: Check script syntax
log "INFO: Testing script syntax..."
for script in "$SCRIPT_DIR"/*.sh; do
    if [ "$(basename "$script")" = "validate.sh" ]; then
        continue
    fi
    
    if bash -n "$script"; then
        log "INFO: ✓ $(basename "$script") syntax OK"
    else
        log "ERROR: ✗ $(basename "$script") syntax error"
        exit 1
    fi
done

# Test 2: Check help functions work
log "INFO: Testing help functions..."
if "$SCRIPT_DIR/shulker-autoinstall.sh" --help >/dev/null 2>&1; then
    log "INFO: ✓ shulker-autoinstall.sh help works"
else
    log "ERROR: ✗ shulker-autoinstall.sh help failed"
    exit 1
fi

if "$SCRIPT_DIR/auto-install-nixos.sh" --help >/dev/null 2>&1; then
    log "INFO: ✓ auto-install-nixos.sh help works"
else
    log "ERROR: ✗ auto-install-nixos.sh help failed"
    exit 1
fi

# Test 3: Check dry-run modes work
log "INFO: Testing dry-run functionality..."
if "$SCRIPT_DIR/auto-install-nixos.sh" --dry-run >/dev/null 2>&1; then
    log "INFO: ✓ auto-install-nixos.sh dry-run works"
else
    log "ERROR: ✗ auto-install-nixos.sh dry-run failed"
    exit 1
fi

# Test 4: Check script permissions
log "INFO: Testing script permissions..."
for script in "$SCRIPT_DIR"/*.sh; do
    if [ -x "$script" ]; then
        log "INFO: ✓ $(basename "$script") is executable"
    else
        log "ERROR: ✗ $(basename "$script") is not executable"
        exit 1
    fi
done

# Test 5: Check required tools would be available
log "INFO: Checking for required tools in PATH..."
REQUIRED_TOOLS=(
    "bash"
    "date"
    "mkdir"
    "chmod"
    "ln"
    "cat"
    "tee"
)

for tool in "${REQUIRED_TOOLS[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
        log "INFO: ✓ $tool available"
    else
        log "WARNING: ✗ $tool not found (may be available in ISO environment)"
    fi
done

log "INFO: ✓ All validation tests passed!"
log "INFO: Shulker-installer automation scripts are ready for use"

exit 0