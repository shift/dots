#!/usr/bin/env bash

# MCP Configuration Validation Script
# This script validates the MCP server configuration without requiring Nix

set -euo pipefail

echo "🔍 Validating MCP Server Configuration..."

# Check if required files exist
FILES_TO_CHECK=(
    "modules/mcp-servers.nix"
    "users/shift/mcp.nix"
    "docs/MCP_SETUP.md"
)

echo "📁 Checking configuration files..."
for file in "${FILES_TO_CHECK[@]}"; do
    if [[ -f "$file" ]]; then
        echo "  ✅ $file exists"
    else
        echo "  ❌ $file missing"
        exit 1
    fi
done

# Validate Nix syntax using basic checks
echo "🔧 Checking Nix syntax..."

# Check for common syntax issues
check_nix_file() {
    local file="$1"
    echo "  Checking $file..."
    
    # Basic brace matching
    if ! awk '
    BEGIN { braces=0; brackets=0; parens=0 }
    {
        for(i=1; i<=length($0); i++) {
            c = substr($0, i, 1)
            if(c == "{") braces++
            else if(c == "}") braces--
            else if(c == "[") brackets++
            else if(c == "]") brackets--
            else if(c == "(") parens++
            else if(c == ")") parens--
        }
    }
    END { 
        if(braces != 0) { print "Unmatched braces: " braces; exit 1 }
        if(brackets != 0) { print "Unmatched brackets: " brackets; exit 1 }
        if(parens != 0) { print "Unmatched parentheses: " parens; exit 1 }
    }' "$file"; then
        echo "    ❌ Syntax error in $file"
        return 1
    fi
    
    # Check for required sections
    if [[ "$file" == "modules/mcp-servers.nix" ]]; then
        if ! grep -q "options\.services\.mcp-servers" "$file"; then
            echo "    ❌ Missing options.services.mcp-servers in $file"
            return 1
        fi
        if ! grep -q "config = mkIf cfg\.enable" "$file"; then
            echo "    ❌ Missing config section in $file"
            return 1
        fi
    fi
    
    echo "    ✅ $file syntax OK"
}

for file in modules/mcp-servers.nix users/shift/mcp.nix; do
    check_nix_file "$file"
done

# Check host configuration integration
echo "🏠 Checking host configuration..."
if grep -q "services\.mcp-servers" hosts/shulkerbox.nix; then
    echo "  ✅ MCP servers enabled in host configuration"
else
    echo "  ❌ MCP servers not configured in host"
    exit 1
fi

if grep -q "github_copilot_token" hosts/shulkerbox.nix; then
    echo "  ✅ GitHub token secret configured"
else
    echo "  ❌ GitHub token secret not configured"
    exit 1
fi

# Check user configuration integration
echo "👤 Checking user configuration..."
if grep -q "copilot-lua" users/shift/nixvim.nix && grep -q "enable = true" users/shift/nixvim.nix; then
    echo "  ✅ Copilot enabled in nixvim"
else
    echo "  ❌ Copilot not enabled in nixvim"
    exit 1
fi

if grep -q "mcp\.nix" users/shift/default.nix; then
    echo "  ✅ MCP module imported in user configuration"
else
    echo "  ❌ MCP module not imported in user configuration"
    exit 1
fi

# Check module imports
echo "📦 Checking module imports..."
if grep -q "mcp-servers\.nix" modules/default.nix; then
    echo "  ✅ MCP servers module imported"
else
    echo "  ❌ MCP servers module not imported"
    exit 1
fi

# Check documentation
echo "📚 Checking documentation..."
if [[ -f "docs/MCP_SETUP.md" ]]; then
    if grep -q "GitHub Personal Access Token" docs/MCP_SETUP.md; then
        echo "  ✅ Documentation includes token setup"
    else
        echo "  ⚠️  Documentation missing token setup instructions"
    fi
    
    if grep -q "nixos-rebuild" docs/MCP_SETUP.md; then
        echo "  ✅ Documentation includes rebuild instructions"
    else
        echo "  ⚠️  Documentation missing rebuild instructions"
    fi
fi

echo ""
echo "🎉 All validation checks passed!"
echo ""
echo "Next steps:"
echo "1. Add GitHub Personal Access Token to SOPS secrets"
echo "2. Run 'sudo nixos-rebuild switch --flake .#shulkerbox'"
echo "3. Verify MCP servers are working with 'npx @modelcontextprotocol/inspector'"