# dots - Device Orchestration, Totally Simplified

A comprehensive NixOS configuration management system for multiple devices and users.

## Features

- **Multi-user Configuration**: Separate configurations for different users (shift, dio, squeals)
- **Modular Design**: Reusable modules for common functionality
- **MCP Servers**: Pre-configured Model Context Protocol servers for AI development tools
- **Secrets Management**: Integrated SOPS for secure credential management
- **Hardware Support**: Specialized configurations for different hardware platforms

## MCP (Model Context Protocol) Servers

This configuration includes comprehensive MCP server setup for AI development tools like Claude Desktop and Cursor IDE. The MCP servers provide AI tools with access to:

- File system operations
- Git version control
- GitHub API access
- Shell command execution
- Database operations (SQLite, PostgreSQL)
- Web search and automation
- And more

See [docs/mcp-servers.md](docs/mcp-servers.md) for detailed setup instructions.
