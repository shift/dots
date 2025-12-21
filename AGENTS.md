# AGENTS.md - Repository Guidelines

## Build & Development Commands

```bash
# Format all code
treefmt

# Check and fix Nix code quality
statix fix
deadnix -e

# Build configurations
nix build .#nixosConfigurations.shulkerbox.config.system.build.isoImage
nix build .#shulkerbox-installer-signed

# Enter development shell
nix develop
```

## Code Style Guidelines

### Nix Files
- Use `nixfmt-rfc-style` for formatting (RFC 140)
- Use `lib.mkForce` instead of `lib.mkDefault` when overriding
- Keep module imports alphabetical where possible
- Use proper indentation (2 spaces for nested Nix expressions)

### File Organization
- Host configs in `hosts/`
- User home configs in `users/`  
- NixOS modules in `nixos/` and `modules/`
- Disk configs in `disks/`
- Secrets in `secrets/` (encrypted with SOPS)

### Security
- Never commit secrets or keys directly
- Use SOPS for secret management
- Keep secure boot keys in `secrets/secureboot/`
- All system packages must go through flake inputs

### Error Handling
- Use `lib.optionals` for conditional features
- Provide clear error messages in shell scripts
- Validate inputs before processing

### Testing
- Validate ISO builds before deployment
- Test SOPS decryption on target hosts
- Verify secure boot key enrollment