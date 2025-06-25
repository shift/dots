{ pkgs, config, lib, ... }:

{
  imports = [ ../shift/mcp-module.nix ];

  # Basic MCP servers configuration for dio user
  services.mcp-servers = {
    enable = true;
    enableDefaultServers = true;
    
    # Additional servers for multimedia and creative work
    servers = {
      # Puppeteer for web-based tools and automation
      puppeteer = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [ "@modelcontextprotocol/server-puppeteer" ];
      };

      # Memory for persistent context across sessions
      memory = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [ "@modelcontextprotocol/server-memory" ];
      };
    };
  };
}