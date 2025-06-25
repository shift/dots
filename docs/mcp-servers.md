# MCP Servers Configuration

This directory contains the Model Context Protocol (MCP) server configurations for AI development tools like Claude Desktop and Cursor IDE.

## What are MCP Servers?

MCP (Model Context Protocol) servers provide AI tools with access to external systems and data sources. This allows AI assistants to:

- Read and write files
- Execute shell commands
- Access GitHub repositories
- Query databases
- Search the web
- And much more

## Configured Servers

### Default Servers (automatically enabled)

1. **Filesystem** - File system operations (read, write, list files)
2. **Git** - Git version control operations
3. **GitHub** - GitHub API access for repository management
4. **Bash** - Shell command execution
5. **SQLite** - SQLite database operations

### Additional Servers

1. **Brave Search** - Web search capabilities
2. **Puppeteer** - Web automation and scraping
3. **Memory** - Persistent memory across AI sessions
4. **Everything** - File indexing and search
5. **Postgres** - PostgreSQL database operations

## Setup

### 1. Install MCP Server Packages

After applying the NixOS configuration, run:

```bash
~/.local/bin/install-mcp-servers
```

This will install all the required npm packages for the MCP servers.

### 2. Configure Environment Variables

Set the following environment variables in your shell profile or secrets management:

```bash
# Required for GitHub server
export GITHUB_PERSONAL_ACCESS_TOKEN="your_github_token_here"

# Required for Brave Search server
export BRAVE_API_KEY="your_brave_api_key_here"

# Optional: Required for Postgres server
export POSTGRES_CONNECTION_STRING="postgresql://user:password@localhost:5432/dbname"
```

### 3. Supported AI Tools

The configuration automatically creates config files for:

- **Claude Desktop**: `~/.config/claude-desktop/claude_desktop_config.json`
- **Cursor IDE**: `~/.cursor/mcp_settings.json`

## Customization

To add or modify MCP servers, edit the configuration in:
- `modules/mcp-servers.nix` (system-wide defaults)
- `users/shift/mcp-servers.nix` (user-specific servers)

## Getting API Keys

### GitHub Personal Access Token
1. Go to GitHub Settings → Developer Settings → Personal Access Tokens
2. Create a new token with appropriate repository permissions
3. Set the `GITHUB_PERSONAL_ACCESS_TOKEN` environment variable

### Brave Search API Key
1. Visit [Brave Search API](https://api.search.brave.com/)
2. Sign up and get your API key
3. Set the `BRAVE_API_KEY` environment variable

## Security Notes

- Never commit API keys or tokens to version control
- Use the secrets management system or environment variables
- The configuration files use environment variable substitution (`${VAR_NAME}`)
- Actual values are resolved at runtime, not build time