{ pkgs, config, lib, ... }:

{
  # Minimal MCP servers configuration for squeals user
  services.mcp-servers = {
    enable = true;
    enableDefaultServers = true;
    
    # Only basic servers - filesystem, git, bash for development
    servers = {
      # Limit filesystem access to home directory for security
      filesystem = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [ "@modelcontextprotocol/server-filesystem" "${config.home.homeDirectory}" ];
      };
    };
  };
}