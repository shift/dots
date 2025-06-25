{ config, lib, pkgs, ... }:

{
  # System-wide MCP support configuration
  
  # Ensure Node.js is available system-wide for MCP servers
  environment.systemPackages = with pkgs; [
    nodejs
    git
  ];

  # System-wide environment variables for MCP development
  environment.variables = {
    # Hint that MCP servers are available
    MCP_SERVERS_AVAILABLE = "true";
  };

  # Enable development tools that work well with MCP
  programs.git.enable = true;
  
  # Optional: Install development packages that complement MCP servers
  environment.systemPackages = with pkgs; [
    sqlite
    curl
    wget
    jq  # JSON processing for MCP server responses
  ];
}