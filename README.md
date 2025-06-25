# dots - Device Orchestration, Totally Simplified

A comprehensive NixOS configuration for development environments with integrated tooling and automation.

## Features

- **Nix Flakes** - Reproducible system configurations
- **Home Manager** - User environment management
- **SOPS** - Secrets management
- **Stylix** - System-wide theming
- **MCP Servers** - GitHub Copilot integration with Model Context Protocol servers

## Quick Start

1. Clone this repository
2. Configure secrets (see [SOPS setup](docs/MCP_SETUP.md#setup-instructions))
3. Build and switch: `sudo nixos-rebuild switch --flake .#shulkerbox`

## MCP Server Integration

This configuration includes MCP (Model Context Protocol) servers for enhanced GitHub Copilot functionality:

- **GitHub MCP Server** - Repository access and operations
- **Filesystem MCP Server** - Secure file system interactions
- **Shell MCP Server** - Command execution capabilities

See [docs/MCP_SETUP.md](docs/MCP_SETUP.md) for detailed setup instructions.

## Validation

Run the configuration validator:
```bash
./scripts/validate-mcp.sh
```
