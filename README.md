# dots - Device Orchestration, Totally Simplified

## Shulker Installer Automation

The shulker-installer ISO now includes automated installation capabilities with Secure Boot support.

### Quick Start

1. **Boot from shulker-installer ISO**
2. **Enable Setup Mode** in BIOS/UEFI if needed
3. **Run automated installer**:
   ```bash
   shulker-install
   ```

### Features

- **Secure Boot Detection**: Automatically detects if system is in setup mode
- **Key Installation**: Automated secure boot key enrollment using sbctl
- **NixOS Installation**: Automated deployment using nixos-anywhere
- **ISO Signing**: Sign installer ISOs for secure boot compatibility
- **Remote Installation**: Support for installing on remote machines

### Scripts

See `installer-scripts/README.md` for detailed documentation of all automation scripts.

### Manual Installation

Traditional manual installation is still supported alongside the new automation.
