{ ... }:
{
  imports = [
    ./monitoring.nix
    ./shared-sudo-auth.nix
    ./mcp-servers.nix
  ];
}
