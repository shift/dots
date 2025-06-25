# MCP (Model Context Protocol) Servers Setup

This document describes the MCP server setup for enabling GitHub Copilot functionality in the `dots` repository.

## Overview

MCP (Model Context Protocol) servers enable AI tools like GitHub Copilot to interact with various systems and services. This setup provides:

- **GitHub MCP Server**: Access to GitHub repositories, issues, and pull requests
- **Filesystem MCP Server**: Secure file system operations 
- **Shell MCP Server**: Command execution capabilities

## Architecture

### System-level Configuration (`modules/mcp-servers.nix`)

The system-level MCP configuration provides:
- Node.js runtime for MCP servers
- Security policies for sudo access
- Systemd services for token management
- Global environment configuration

### User-level Configuration (`users/shift/mcp.nix`) 

The user-level configuration provides:
- Personal MCP client setup
- Shell integration (zsh/bash)
- XDG desktop entries
- Git configuration for Copilot

### Host Configuration (`hosts/shulkerbox.nix`)

The host enables:
- GitHub MCP server with SOPS-managed token
- Filesystem access to user home and projects
- Shell command execution

## Security Considerations

### Token Management
- GitHub Personal Access Token stored in SOPS secrets
- Token file permissions set to 0400 (read-only for owner)
- Environment variables loaded securely at runtime

### Filesystem Access
- Limited to specific allowed paths: `/home/shift`, `/tmp`, `/home/shift/projects`
- No access to system-critical directories
- User-owned file operations only

### Shell Access  
- Sudo rules configured for Node.js/NPX execution
- Limited to MCP-related commands
- No root shell access granted

## Setup Instructions

### 1. Generate GitHub Personal Access Token

Create a GitHub Personal Access Token with these scopes:
- `repo` - Full repository access
- `read:org` - Read organization membership
- `read:user` - Read user profile
- `user:email` - Read user email

### 2. Add Token to SOPS

Add the token to your SOPS secrets file:

```yaml
# secrets/common.yaml
github_copilot_token: "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

### 3. Re-encrypt Secrets

```bash
sops updatekeys secrets/common.yaml
```

### 4. Rebuild System

```bash
sudo nixos-rebuild switch --flake .#shulkerbox
```

## Usage

### Neovim/Nixvim Integration

Copilot is automatically enabled in Neovim with these keybindings:

- `<Alt-l>` - Accept suggestion
- `<Alt-w>` - Accept word
- `<Alt-j>` - Accept line  
- `<Alt-]>` - Next suggestion
- `<Alt-[>` - Previous suggestion
- `<Ctrl-]>` - Dismiss suggestion

### Panel Commands

- `<Alt-Enter>` - Open Copilot panel
- `[[` - Jump to previous suggestion
- `]]` - Jump to next suggestion
- `<Enter>` - Accept suggestion
- `gr` - Refresh suggestions

### MCP Server Status

Check MCP server status:
```bash
npx @modelcontextprotocol/inspector
```

### Environment Variables

The following environment variables are automatically configured:
- `MCP_CONFIG_PATH` - Path to MCP configuration
- `GITHUB_PERSONAL_ACCESS_TOKEN` - GitHub token (loaded from SOPS)

## Troubleshooting

### Common Issues

1. **Token not found**
   - Verify SOPS secret exists: `sops -d secrets/common.yaml | grep github_copilot_token`
   - Check file permissions: `ls -la /run/secrets/github_copilot_token`

2. **Node.js not found**
   - Ensure Node.js is in PATH: `which node`
   - Restart shell after configuration changes

3. **Copilot not suggesting**
   - Check Neovim health: `:checkhealth copilot`
   - Verify token permissions on GitHub
   - Check network connectivity

### Debug Mode

Enable verbose logging:
```bash
export COPILOT_LOG_LEVEL=debug
nvim
```

### Service Logs

Check systemd logs:
```bash
journalctl -u mcp-github-token.service
```

## Configuration Files

### Generated Files
- `/home/shift/.config/mcp/config.json` - MCP client configuration
- `/run/secrets/github_copilot_token` - GitHub token (SOPS managed)

### Configuration Paths
- System: `/etc/nixos/modules/mcp-servers.nix`
- User: `/etc/nixos/users/shift/mcp.nix`
- Host: `/etc/nixos/hosts/shulkerbox.nix`

## Maintenance

### Updating MCP Servers

MCP servers are installed via NPX and automatically updated. To force update:
```bash
npm cache clean --force
npx --yes @modelcontextprotocol/server-github@latest
```

### Rotating GitHub Token

1. Generate new token on GitHub
2. Update SOPS secret: `sops secrets/common.yaml`
3. Rebuild system: `sudo nixos-rebuild switch --flake .#shulkerbox`

### Monitoring

Monitor MCP server performance through:
- System resource usage
- Network connections to GitHub API
- Token usage limits on GitHub

## Integration with Other Tools

### VS Code (Optional)

For VS Code integration, install the GitHub Copilot extension and configure:
```json
{
  "github.copilot.enable": {
    "*": true,
    "yaml": true,
    "plaintext": true,
    "markdown": true
  }
}
```

### Shell Completion

MCP servers can provide intelligent shell completion. Configure with:
```bash
eval "$(mcp completion)"
```

## References

- [Model Context Protocol Specification](https://modelcontextprotocol.io/)
- [GitHub Copilot Documentation](https://docs.github.com/en/copilot)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [SOPS-NIX Documentation](https://github.com/Mic92/sops-nix)