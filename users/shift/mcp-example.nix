{ pkgs, config, lib, ... }:

{
  # Example configuration for other users who want minimal MCP setup
  services.mcp-servers = {
    enable = true;
    enableDefaultServers = true;
    
    # Override specific servers if needed
    servers = {
      # Only enable basic servers for development
      filesystem = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [ "@modelcontextprotocol/server-filesystem" "${config.home.homeDirectory}/projects" ];
      };
      
      # Custom server example - you can add any MCP server here
      # custom-server = {
      #   command = "/path/to/custom/mcp/server";
      #   args = [ "--config" "/path/to/config" ];
      #   env = {
      #     CUSTOM_API_KEY = "${CUSTOM_API_KEY}";
      #   };
      # };
    };
  };

  # Minimal package set for MCP
  home.packages = with pkgs; [
    nodejs
    git
  ];
}