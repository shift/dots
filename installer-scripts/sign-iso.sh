#!/usr/bin/env bash
# Sign the shulker-installer ISO with secure boot keys
# This script should be run after the ISO is built

set -euo pipefail

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

# Configuration
SECUREBOOT_KEYS_DIR="/etc/secureboot"
DB_KEY="$SECUREBOOT_KEYS_DIR/keys/db/db.key"
DB_CRT="$SECUREBOOT_KEYS_DIR/keys/db/db.pem"

show_help() {
    cat << EOF
Usage: $0 [OPTIONS] ISO_FILE

Sign a shulker-installer ISO with secure boot keys.

Options:
    -h, --help          Show this help message
    -k, --key PATH      Path to signing key (default: $DB_KEY)
    -c, --cert PATH     Path to signing certificate (default: $DB_CRT)
    -o, --output PATH   Output path for signed ISO (default: same as input with .signed suffix)
    --verify            Verify signature after signing

Examples:
    $0 shulkerbox-installer.iso
    $0 -o signed-installer.iso shulkerbox-installer.iso
    $0 --verify shulkerbox-installer.iso
EOF
}

# Default values
ISO_FILE=""
OUTPUT_FILE=""
VERIFY_SIGNATURE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -k|--key)
            DB_KEY="$2"
            shift 2
            ;;
        -c|--cert)
            DB_CRT="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --verify)
            VERIFY_SIGNATURE=true
            shift
            ;;
        -*)
            log "ERROR: Unknown option: $1"
            show_help
            exit 1
            ;;
        *)
            if [ -z "$ISO_FILE" ]; then
                ISO_FILE="$1"
            else
                log "ERROR: Multiple ISO files specified"
                show_help
                exit 1
            fi
            shift
            ;;
    esac
done

# Check if ISO file is provided
if [ -z "$ISO_FILE" ]; then
    log "ERROR: ISO file must be specified"
    show_help
    exit 1
fi

# Check if ISO file exists
if [ ! -f "$ISO_FILE" ]; then
    log "ERROR: ISO file not found: $ISO_FILE"
    exit 1
fi

# Set default output file if not specified
if [ -z "$OUTPUT_FILE" ]; then
    OUTPUT_FILE="${ISO_FILE%.*}.signed.${ISO_FILE##*.}"
fi

# Check if signing keys exist
if [ ! -f "$DB_KEY" ]; then
    log "ERROR: Signing key not found: $DB_KEY"
    exit 1
fi

if [ ! -f "$DB_CRT" ]; then
    log "ERROR: Signing certificate not found: $DB_CRT"
    exit 1
fi

# Check if required tools are available
if ! command -v sbsign >/dev/null 2>&1; then
    log "ERROR: sbsign not found. Please install sbsigntools."
    exit 1
fi

if ! command -v pesign >/dev/null 2>&1; then
    log "WARNING: pesign not found. Some signature verification may not work."
fi

log "INFO: Starting ISO signing process"
log "INFO: Input ISO: $ISO_FILE"
log "INFO: Output ISO: $OUTPUT_FILE"
log "INFO: Using key: $DB_KEY"
log "INFO: Using certificate: $DB_CRT"

# Create a temporary directory for working
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Extract the ISO to get the bootloader components
log "INFO: Extracting ISO contents"
cd "$TEMP_DIR"
if ! 7z x "$ISO_FILE" >/dev/null 2>&1; then
    log "ERROR: Failed to extract ISO. Is 7z installed?"
    exit 1
fi

# Find EFI boot files to sign
log "INFO: Finding EFI boot files to sign"
EFI_FILES=()
while IFS= read -r -d '' file; do
    EFI_FILES+=("$file")
done < <(find . -name "*.efi" -print0)

if [ ${#EFI_FILES[@]} -eq 0 ]; then
    log "WARNING: No EFI files found to sign"
else
    log "INFO: Found ${#EFI_FILES[@]} EFI files to sign"
fi

# Sign each EFI file
for efi_file in "${EFI_FILES[@]}"; do
    log "INFO: Signing $efi_file"
    
    # Create backup
    cp "$efi_file" "$efi_file.unsigned"
    
    # Sign the file
    if ! sbsign --key "$DB_KEY" --cert "$DB_CRT" --output "$efi_file" "$efi_file.unsigned"; then
        log "ERROR: Failed to sign $efi_file"
        exit 1
    fi
    
    log "INFO: Successfully signed $efi_file"
done

# Recreate the ISO with signed components
log "INFO: Recreating signed ISO"

# Try different methods to create the ISO depending on available tools
if command -v genisoimage >/dev/null 2>&1; then
    # Use genisoimage (part of cdrtools)
    genisoimage -o "$OUTPUT_FILE" \
        -b isolinux/isolinux.bin \
        -c isolinux/boot.cat \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        -eltorito-alt-boot \
        -e boot/grub/efi.img \
        -no-emul-boot \
        -R -J -v -T \
        .
elif command -v mkisofs >/dev/null 2>&1; then
    # Use mkisofs
    mkisofs -o "$OUTPUT_FILE" \
        -b isolinux/isolinux.bin \
        -c isolinux/boot.cat \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        -eltorito-alt-boot \
        -e boot/grub/efi.img \
        -no-emul-boot \
        -R -J -v -T \
        .
elif command -v xorriso >/dev/null 2>&1; then
    # Use xorriso
    xorriso -as mkisofs -o "$OUTPUT_FILE" \
        -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
        -c isolinux/boot.cat \
        -b isolinux/isolinux.bin \
        -no-emul-boot -boot-load-size 4 -boot-info-table \
        -eltorito-alt-boot \
        -e boot/grub/efi.img \
        -no-emul-boot \
        -isohybrid-gpt-basdat \
        .
else
    log "ERROR: No suitable ISO creation tool found (need genisoimage, mkisofs, or xorriso)"
    exit 1
fi

if [ ! -f "$OUTPUT_FILE" ]; then
    log "ERROR: Failed to create signed ISO"
    exit 1
fi

log "INFO: Successfully created signed ISO: $OUTPUT_FILE"

# Verify the signature if requested
if $VERIFY_SIGNATURE; then
    log "INFO: Verifying signatures"
    
    # Extract the signed ISO to verify
    VERIFY_DIR=$(mktemp -d)
    cd "$VERIFY_DIR"
    
    if 7z x "$OUTPUT_FILE" >/dev/null 2>&1; then
        # Check signatures on EFI files
        while IFS= read -r -d '' file; do
            if command -v sbverify >/dev/null 2>&1; then
                if sbverify --cert "$DB_CRT" "$file" >/dev/null 2>&1; then
                    log "INFO: ✓ $file signature is valid"
                else
                    log "WARNING: ✗ $file signature verification failed"
                fi
            else
                log "INFO: ? $file (sbverify not available for verification)"
            fi
        done < <(find . -name "*.efi" -print0)
    else
        log "WARNING: Could not extract signed ISO for verification"
    fi
    
    rm -rf "$VERIFY_DIR"
fi

# Show file sizes
ORIGINAL_SIZE=$(stat -f%z "$ISO_FILE" 2>/dev/null || stat -c%s "$ISO_FILE")
SIGNED_SIZE=$(stat -f%z "$OUTPUT_FILE" 2>/dev/null || stat -c%s "$OUTPUT_FILE")

log "INFO: Original ISO size: $(numfmt --to=iec-i --suffix=B "$ORIGINAL_SIZE")"
log "INFO: Signed ISO size: $(numfmt --to=iec-i --suffix=B "$SIGNED_SIZE")"

log "INFO: ISO signing completed successfully!"
log "INFO: Signed ISO: $OUTPUT_FILE"

exit 0