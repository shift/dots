{ ... }:
{
  imports = [
    ./niri.nix
    ./waybar/default.nix
    ./fuzzel.nix
  ];
  home.stateVersion = "25.05"; # Don't change this. This will not upgrade your home-manager.
  programs.home-manager.enable = true;
  programs.neovim.enable = true;

  # Enable niri window manager
  shift.niri.enable = true;
}
