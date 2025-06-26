# Shulker Installer Scripts

This directory contains automation scripts for the shulker-installer ISO to provide seamless installation with Secure Boot support.

## Scripts Overview

### `shulker-autoinstall.sh`
**Main orchestration script** that coordinates the entire installation process.

Usage:
```bash
# Full automated installation
shulker-autoinstall.sh

# Check system status
shulker-autoinstall.sh status

# Install only secure boot keys
shulker-autoinstall.sh install-keys

# Install only NixOS (skip secure boot)
shulker-autoinstall.sh install-nixos

# Skip secure boot and install NixOS only
shulker-autoinstall.sh --skip-secureboot install
```

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

### `sign-iso.sh`
Signs the installer ISO with Secure Boot keys for compatibility.

Features:
- Extracts and re-signs EFI boot files
- Recreates signed ISO
- Signature verification
- Multiple ISO creation tool support

## Quick Start

When booted from the shulker-installer ISO, you can use these convenient aliases:

```bash
# Check system status and requirements
shulker-status

# Full automated installation (secure boot + NixOS)
shulker-install

# Install secure boot keys only
install-secureboot

# Check if in setup mode
check-setup-mode
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