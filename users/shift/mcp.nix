{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.mcp-client;

  # MCP client configuration for various tools
  mcpClientConfig = {
    mcpServers = {
      github = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-github"
        ];
        env = {
          GITHUB_PERSONAL_ACCESS_TOKEN = "\${GITHUB_PERSONAL_ACCESS_TOKEN}";
        };
      };
      filesystem = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-filesystem"
          "${config.home.homeDirectory}"
          "${config.home.homeDirectory}/projects"
          "/tmp"
        ];
      };
      shell = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-shell"
        ];
      };
    };
  };

  mcpConfigFile = pkgs.writeTextFile {
    name = "mcp-client-config.json";
    text = builtins.toJSON mcpClientConfig;
  };

in
{
  options.programs.mcp-client = {
    enable = mkEnableOption "MCP client configuration for development tools";

    configPath = mkOption {
      type = types.str;
      default = "${config.xdg.configHome}/mcp";
      description = "Path where MCP client configuration will be stored";
    };
  };

  config = mkIf cfg.enable {
    # Ensure Node.js is available for the user
    home.packages = with pkgs; [
      nodejs
      npm
    ];

    # Create MCP configuration directory and files
    home.file."${cfg.configPath}/config.json".source = mcpConfigFile;

    # Shell integration for MCP
    programs.zsh.initExtra = mkIf config.programs.zsh.enable ''
      # MCP environment setup
      export MCP_CONFIG_PATH="${cfg.configPath}"
      
      # Load GitHub token if available
      if [ -f "/run/secrets/github_copilot_token" ]; then
        export GITHUB_PERSONAL_ACCESS_TOKEN="$(cat /run/secrets/github_copilot_token)"
      fi
    '';

    programs.bash.initExtra = mkIf config.programs.bash.enable ''
      # MCP environment setup
      export MCP_CONFIG_PATH="${cfg.configPath}"
      
      # Load GitHub token if available
      if [ -f "/run/secrets/github_copilot_token" ]; then
        export GITHUB_PERSONAL_ACCESS_TOKEN="$(cat /run/secrets/github_copilot_token)"
      fi
    '';

    # Git configuration for Copilot integration
    programs.git.extraConfig = {
      "copilot" = {
        enable = true;
      };
    };

    # XDG desktop entry for MCP tools (optional)
    xdg.desktopEntries.mcp-status = {
      name = "MCP Server Status";
      comment = "Check status of MCP servers";
      exec = "${pkgs.nodejs}/bin/npx @modelcontextprotocol/inspector";
      icon = "applications-development";
      categories = [ "Development" ];
    };
  };
}