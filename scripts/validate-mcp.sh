#!/usr/bin/env bash
set -e

echo "🔍 Validating MCP Servers Configuration..."

# Check if Node.js is available
if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found. Make sure to run 'nixos-rebuild switch' first."
    exit 1
fi

echo "✅ Node.js available: $(node --version)"

# Check if npm is available
if ! command -v npm &> /dev/null; then
    echo "❌ npm not found."
    exit 1
fi

echo "✅ npm available: $(npm --version)"

# Check if MCP configuration files exist
config_files=(
    "$HOME/.config/claude-desktop/claude_desktop_config.json"
    "$HOME/.cursor/mcp_settings.json"
)

for config_file in "${config_files[@]}"; do
    if [[ -f "$config_file" ]]; then
        echo "✅ Configuration file exists: $config_file"
        # Validate JSON syntax
        if jq empty "$config_file" 2>/dev/null; then
            echo "✅ Valid JSON syntax: $config_file"
        else
            echo "❌ Invalid JSON syntax: $config_file"
        fi
    else
        echo "⚠️  Configuration file not found: $config_file"
        echo "   This is normal if the MCP module hasn't been activated yet."
    fi
done

# Check if install script exists
if [[ -x "$HOME/.local/bin/install-mcp-servers" ]]; then
    echo "✅ MCP server install script available"
else
    echo "❌ MCP server install script not found or not executable"
fi

# Check environment variables
env_vars=("GITHUB_PERSONAL_ACCESS_TOKEN" "BRAVE_API_KEY" "POSTGRES_CONNECTION_STRING")
for var in "${env_vars[@]}"; do
    if [[ -n "${!var}" ]]; then
        echo "✅ Environment variable set: $var"
    else
        echo "⚠️  Environment variable not set: $var (optional)"
    fi
done

echo ""
echo "🎉 MCP validation complete!"
echo ""
echo "Next steps:"
echo "1. Run: ~/.local/bin/install-mcp-servers"
echo "2. Set up your API keys (see docs/mcp-servers.md)"
echo "3. Start Claude Desktop or Cursor IDE to test MCP integration"