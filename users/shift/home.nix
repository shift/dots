{ ... }:
{
  imports = [
    ./sway.nix
    ./mcp.nix
  ];
  home.stateVersion = "25.05"; # Don't change this. This will not upgrade your home-manager.
  programs.home-manager.enable = true;
  programs.neovim.enable = true;
  
  # Enable MCP client configuration
  programs.mcp-client.enable = true;
}
