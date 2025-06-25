{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.mcp-servers;
in
{
  options.services.mcp-servers = {
    enable = mkEnableOption "MCP (Model Context Protocol) servers";
    
    servers = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          command = mkOption {
            type = types.str;
            description = "Command to run the MCP server";
          };
          
          args = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "Arguments to pass to the MCP server";
          };
          
          env = mkOption {
            type = types.attrsOf types.str;
            default = {};
            description = "Environment variables for the MCP server";
          };
        };
      });
      default = {};
      description = "MCP servers configuration";
    };

    configPath = mkOption {
      type = types.str;
      default = ".config/claude-desktop/claude_desktop_config.json";
      description = "Path to the MCP configuration file relative to home directory";
    };

    enableDefaultServers = mkEnableOption "default MCP servers (filesystem, git, github, bash, sqlite)";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      nodejs
      sqlite
      git
    ] ++ optional (cfg.servers ? postgres || cfg.enableDefaultServers) postgresql;

    services.mcp-servers.servers = mkIf cfg.enableDefaultServers {
      filesystem = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [ "@modelcontextprotocol/server-filesystem" "${config.home.homeDirectory}" ];
      };

      github = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [ "@modelcontextprotocol/server-github" ];
        env = {
          GITHUB_PERSONAL_ACCESS_TOKEN = "\${GITHUB_PERSONAL_ACCESS_TOKEN}";
        };
      };

      git = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [ "@modelcontextprotocol/server-git" ];
      };

      bash = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [ "@modelcontextprotocol/server-bash" ];
      };

      sqlite = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [ "@modelcontextprotocol/server-sqlite" ];
      };
    };

    home.file."${cfg.configPath}" = mkIf (cfg.servers != {}) {
      text = builtins.toJSON {
        mcpServers = cfg.servers;
      };
    };

    # Install script for MCP server packages
    home.file.".local/bin/install-mcp-servers" = {
      text = ''
        #!/bin/bash
        set -e
        
        echo "Installing/updating MCP server packages..."
        
        # Install common MCP servers globally
        ${pkgs.nodejs}/bin/npm install -g \
          @modelcontextprotocol/server-filesystem \
          @modelcontextprotocol/server-github \
          @modelcontextprotocol/server-git \
          @modelcontextprotocol/server-bash \
          @modelcontextprotocol/server-sqlite \
          @modelcontextprotocol/server-brave-search \
          @modelcontextprotocol/server-puppeteer \
          @modelcontextprotocol/server-memory \
          @modelcontextprotocol/server-everything \
          @modelcontextprotocol/server-postgres
        
        echo "MCP servers installed successfully!"
        echo "Configuration written to: ${cfg.configPath}"
        echo "Don't forget to set your environment variables if needed:"
        echo "  GITHUB_PERSONAL_ACCESS_TOKEN"
        echo "  BRAVE_API_KEY" 
        echo "  POSTGRES_CONNECTION_STRING"
      '';
      executable = true;
    };
  };
}