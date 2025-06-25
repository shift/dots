{ ... }:
{
  imports = [
    ./monitoring.nix
    ./mcp-servers.nix
    ./mcp-secrets.nix
    ./shared-sudo-auth.nix
  ];
}
