# Shulker Installer Scripts

This directory contains smart automation scripts for the shulker-installer ISO to provide seamless installation with Secure Boot support and interactive guidance.

## Scripts Overview

### `shulker-autoinstall.sh`
**Main smart orchestration script** that coordinates the entire installation process with intelligent detection and user guidance.

**New Smart Features:**
- 🔐 **SOPS Integration**: Detects new vs existing hosts, sets up SSH-to-AGE keys automatically
- 📱 **QR Code Display**: Shows AGE keys as QR codes for easy copying to SOPS configuration
- 🔍 **TPM2 Detection**: Checks for TPM2 availability for enhanced security
- 💽 **Partition Detection**: Detects existing partitions and guides user appropriately  
- 🔒 **Setup Mode Detection**: Checks Secure Boot setup mode before proceeding
- 💬 **Interactive Guidance**: Uses `gum` TUI for user-friendly guidance when issues arise
- 🚀 **Auto-Install**: Proceeds automatically when all conditions are met

Usage:
```bash
# Smart automated installation with SOPS setup (recommended)
shulker-autoinstall.sh

# Set up SOPS for new host (generates SSH-to-AGE key with QR code)
shulker-autoinstall.sh setup-sops

# Check comprehensive system status  
shulker-autoinstall.sh status

# Install only secure boot keys
shulker-autoinstall.sh install-keys

# Install only NixOS (skip secure boot)
shulker-autoinstall.sh install-nixos

# Force installation despite warnings
shulker-autoinstall.sh --force install
```

**Behavior Flow:**
1. **SOPS Check**: Determines if this is a new host or existing host
   - **New Host**: Generates SSH-to-AGE key, displays QR code, waits for SOPS configuration
   - **Existing Host**: Continues with normal flow
2. **TPM2 Check**: Warns if no TPM2 detected, offers guidance
3. **Partition Check**: If existing partitions found, provides options:
   - View partitions and continue manually
   - Backup and wipe (with confirmations)
   - Cancel installation
4. **Setup Mode Check**: If not in setup mode, provides options:
   - Instructions to enter BIOS/UEFI
   - Skip Secure Boot setup
   - Cancel installation
5. **Auto-Install**: Proceeds automatically if all checks pass

### `detect-setup-mode.sh` 
Detects if the system is in Secure Boot setup mode by checking EFI variables.

Returns:
- `0` if in setup mode
- `1` if not in setup mode  
- `2` if unable to determine

### `install-secureboot-keys.sh`
Automatically installs Secure Boot keys using `sbctl`.

Features:
- Checks if system is in setup mode
- Uses existing keys from `/secureboot` if available
- Creates new keys if needed
- Enrolls keys into EFI variables
- Verifies installation

### `auto-install-nixos.sh`
Automated NixOS installation using `nixos-anywhere`.

Features:
- Configurable target host and flake configuration
- Network setup for localhost installations
- SSH key support for remote installations
- Dry-run mode for testing

### `sign-iso.sh` (DEPRECATED)
⚠️ **This script is deprecated.** ISO signing is now integrated into the flake build process.

**New Way:** Use `nix build .#shulkerbox-installer-signed` to build a signed ISO automatically.

The flake will:
- Build the unsigned ISO
- Sign EFI bootloaders if Secure Boot keys are available at `/etc/secureboot`
- Create the final signed ISO
- Handle all signing complexity automatically

## ISO Building & Signing

### Building Regular ISO
```bash
nix build .#nixosConfigurations.shulkerbox-installer.config.system.build.isoImage
```

### Building Signed ISO (New!)
```bash
nix build .#shulkerbox-installer-signed
```

The signed ISO build will:
- Automatically sign EFI bootloaders if `/etc/secureboot` keys exist
- Fall back to unsigned ISO if no keys available
- Include proper UEFI boot structure for Secure Boot compatibility

## Quick Start

When booted from the shulker-installer ISO, you can use these convenient aliases:

```bash
# Check comprehensive system status (TPM, partitions, setup mode, SOPS, etc.)
shulker-status

# Smart automated installation with interactive guidance
shulker-install

# Set up SOPS for new host (generates SSH-to-AGE key with QR code)
setup-sops

# Install secure boot keys only  
install-secureboot

# Check if in setup mode
check-setup-mode
```

## SOPS New Host Setup

When installing on a new host that isn't configured in the SOPS secrets, the installer will automatically:

1. **Detect** that SOPS secrets cannot be decrypted
2. **Generate** SSH host keys for the new machine  
3. **Convert** SSH key to AGE key format for SOPS
4. **Display** the AGE key as a QR code for easy copying
5. **Wait** for you to add the key to `.sops.yaml` and push changes
6. **Pull** the updated repository and continue installation

### Manual SOPS Setup

You can also run SOPS setup separately:

```bash
# Run SOPS setup for new host
setup-sops
```

This will:
- Generate SSH keys if they don't exist
- Show AGE key as QR code  
- Wait for SOPS configuration updates
- Pull latest repository changes

### Installation Flow

1. **Boot** from the shulker-installer ISO
2. **Run** `shulker-install` for smart automated installation
3. **SOPS Setup** (if new host):
   - QR code displayed with AGE key
   - Add key to `.sops.yaml` in your repository
   - Re-encrypt secrets with new key
   - Commit and push changes
   - Press Enter to continue
4. **Follow guidance** if other issues are detected:
   - TPM2 missing → Optional guidance to enable in BIOS  
   - Existing partitions → Choose to view/wipe/cancel
   - Not in setup mode → Instructions for BIOS setup
5. **Automatic installation** proceeds when conditions are met
6. **Reboot** when complete

### Manual Steps (if needed)

If the automated installer needs manual intervention:

```bash
# View current disk layout
lsblk

# Manually partition disks with disko  
disko --mode disko /repo/disks/shulkerbox/disko.nix

# Continue with NixOS installation only
shulker-install install-nixos
```

## Installation Process

### Full Automated Installation

1. **Boot from shulker-installer ISO**
2. **Enable Setup Mode** in BIOS/UEFI settings (if not already enabled)
3. **Run the installer**:
   ```bash
   shulker-install
   ```

The script will:
1. Check if system is in Secure Boot setup mode
2. Install Secure Boot keys from `/secureboot`
3. Run `nixos-anywhere` to install NixOS
4. Prompt for reboot

### Manual Step-by-Step

```bash
# 1. Check system status
shulker-status

# 2. Verify setup mode
check-setup-mode

# 3. Install secure boot keys
install-secureboot

# 4. Install NixOS
shulker-install install-nixos
```

### Remote Installation

```bash
# Install NixOS on a remote machine
shulker-install install-nixos -t 192.168.1.100

# Use different flake configuration
shulker-install -f /repo#shulkerbox-server install
```

## Configuration

### Environment Variables

The scripts use these key directories:
- `/repo` - Repository with flake configuration
- `/secureboot` - Secure Boot keys and certificates
- `/ssh_keys` - SSH keys for remote access
- `/var/log/shulker-installer.log` - Installation log

### Flake Configuration

Default flake target: `/repo#shulkerbox`

Override with:
```bash
shulker-install -f /repo#your-config install
```

## Troubleshooting

### Common Issues

**"System is not in setup mode"**
- Enable Setup Mode in BIOS/UEFI settings
- Or use `--force` to override (not recommended)

**"Network connectivity required"**
- Ensure network cable is connected
- Configure WiFi if needed: `nmcli device wifi connect SSID password PASSWORD`

**"Secure boot keys not found"**
- Ensure `/secureboot` directory exists with proper keys
- Check ISO was built with secure boot keys included

### Debug Mode

Enable verbose output:
```bash
shulker-install --debug install
```

### Logs

Check installation logs:
```bash
tail -f /var/log/shulker-installer.log
```

## Security Considerations

- The installer includes pre-configured Secure Boot keys
- Keys should be generated specifically for your organization
- Change default SSH passwords immediately after installation
- Review and customize the flake configuration for your needs

## Building Signed ISO

After building the ISO:

```bash
# Sign the ISO with your secure boot keys
./sign-iso.sh shulkerbox-installer.iso

# Verify signatures
./sign-iso.sh --verify shulkerbox-installer.signed.iso
```