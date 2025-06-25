{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.mcp-servers;

  # MCP server configurations
  githubMcpServer = {
    name = "github";
    command = "${pkgs.nodejs}/bin/npx";
    args = [
      "-y"
      "@modelcontextprotocol/server-github"
    ];
    env = {
      GITHUB_PERSONAL_ACCESS_TOKEN = cfg.github.token;
    };
  };

  filesystemMcpServer = {
    name = "filesystem";
    command = "${pkgs.nodejs}/bin/npx";
    args = [
      "-y"
      "@modelcontextprotocol/server-filesystem"
      cfg.filesystem.allowedPaths
    ];
  };

  shellMcpServer = {
    name = "shell";
    command = "${pkgs.nodejs}/bin/npx";
    args = [
      "-y"
      "@modelcontextprotocol/server-shell"
    ];
  };

  # Generate MCP configuration
  mcpConfig = {
    mcpServers = listToAttrs (
      map (server: nameValuePair server.name {
        command = server.command;
        args = server.args;
        env = server.env or {};
      }) cfg.enabledServers
    );
  };

  mcpConfigFile = pkgs.writeTextFile {
    name = "mcp-config.json";
    text = builtins.toJSON mcpConfig;
  };

in
{
  options.services.mcp-servers = {
    enable = mkEnableOption "MCP (Model Context Protocol) servers for GitHub Copilot";

    enabledServers = mkOption {
      type = types.listOf types.attrs;
      default = [];
      description = "List of MCP servers to enable";
    };

    github = {
      enable = mkEnableOption "GitHub MCP server";

      token = mkOption {
        type = types.str;
        description = "GitHub Personal Access Token for the MCP server";
        default = "";
      };

      tokenFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to file containing GitHub Personal Access Token";
      };
    };

    filesystem = {
      enable = mkEnableOption "Filesystem MCP server";

      allowedPaths = mkOption {
        type = types.str;
        default = "/home";
        description = "Comma-separated list of allowed filesystem paths";
      };
    };

    shell = {
      enable = mkEnableOption "Shell MCP server";
    };

    configPath = mkOption {
      type = types.str;
      default = "/etc/mcp";
      description = "Path where MCP configuration will be stored";
    };
  };

  config = mkIf cfg.enable {
    # Enable Node.js for MCP servers
    environment.systemPackages = with pkgs; [
      nodejs
      npm
    ];

    # Build list of enabled servers
    services.mcp-servers.enabledServers = 
      optional cfg.github.enable githubMcpServer ++
      optional cfg.filesystem.enable filesystemMcpServer ++
      optional cfg.shell.enable shellMcpServer;

    # Ensure MCP config directory exists
    system.activationScripts.mcp-setup = ''
      mkdir -p ${cfg.configPath}
      cp ${mcpConfigFile} ${cfg.configPath}/config.json
      chmod 644 ${cfg.configPath}/config.json
    '';

    # Add security considerations
    security.sudo.extraRules = mkIf cfg.shell.enable [
      {
        users = [ "shift" ];
        commands = [
          {
            command = "${pkgs.nodejs}/bin/node";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.nodejs}/bin/npx";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];

    # Environment variables for MCP
    environment.variables = mkIf (cfg.github.enable && cfg.github.token != "") {
      GITHUB_PERSONAL_ACCESS_TOKEN = cfg.github.token;
    };

    # Load GitHub token from file if specified
    systemd.services.mcp-github-token = mkIf (cfg.github.enable && cfg.github.tokenFile != null) {
      description = "Load GitHub token for MCP server";
      wantedBy = [ "multi-user.target" ];
      script = ''
        if [ -f "${cfg.github.tokenFile}" ]; then
          export GITHUB_PERSONAL_ACCESS_TOKEN=$(cat "${cfg.github.tokenFile}")
        fi
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };
  };
}