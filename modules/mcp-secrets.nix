{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.mcp-servers;
in
{
  # Import the secrets if they exist
  config = mkIf cfg.enable {
    # Set environment variables from SOPS secrets if available
    home.sessionVariables = mkMerge [
      (mkIf (config.sops.secrets ? github_personal_access_token) {
        GITHUB_PERSONAL_ACCESS_TOKEN = "${config.sops.secrets.github_personal_access_token.path}";
      })
      (mkIf (config.sops.secrets ? brave_api_key) {
        BRAVE_API_KEY = "${config.sops.secrets.brave_api_key.path}";
      })
      (mkIf (config.sops.secrets ? postgres_connection_string) {
        POSTGRES_CONNECTION_STRING = "${config.sops.secrets.postgres_connection_string.path}";
      })
    ];
  };
}