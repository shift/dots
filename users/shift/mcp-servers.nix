{ pkgs, config, lib, ... }:

{
  # Enable MCP (Model Context Protocol) servers for AI development tools
  services.mcp-servers = {
    enable = true;
    enableDefaultServers = true;
    
    # Additional MCP servers beyond the defaults
    servers = {
      # Brave Search server for web searches
      brave-search = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [ "@modelcontextprotocol/server-brave-search" ];
        env = {
          BRAVE_API_KEY = "\${BRAVE_API_KEY}";
        };
      };

      # Puppeteer server for web automation
      puppeteer = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [ "@modelcontextprotocol/server-puppeteer" ];
      };

      # Memory server for persistent memory across sessions
      memory = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [ "@modelcontextprotocol/server-memory" ];
      };

      # Everything server for file indexing and search
      everything = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [ "@modelcontextprotocol/server-everything" ];
      };

      # Postgres server for PostgreSQL database operations
      postgres = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [ "@modelcontextprotocol/server-postgres" ];
        env = {
          POSTGRES_CONNECTION_STRING = "\${POSTGRES_CONNECTION_STRING}";
        };
      };
    };
  };

  # Also create configuration for Cursor IDE
  home.file.".cursor/mcp_settings.json" = {
    text = builtins.toJSON {
      mcpServers = config.services.mcp-servers.servers;
    };
  };

  # Environment variables for MCP servers (commented out - set in secrets or shell)
  # home.sessionVariables = {
  #   GITHUB_PERSONAL_ACCESS_TOKEN = "your_token_here";
  #   BRAVE_API_KEY = "your_brave_api_key_here";
  #   POSTGRES_CONNECTION_STRING = "postgresql://user:password@localhost:5432/dbname";
  # };
}