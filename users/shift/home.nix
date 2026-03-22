{ inputs', ... }:
{
  imports = [
    inputs'.dots.homeManagerModules.dynamic-profiles
    ./waybar/default.nix
    ./fuzzel.nix
  ];
  home.stateVersion = "25.05"; # Don't change this. This will not upgrade your home-manager.
  programs.home-manager.enable = true;
  programs.neovim.enable = true;

  # Enable dots framework profiles
  features.dynamic-profiles = {
    jsonContent = ''
      {
        "base": true,
        "printing": true,
        "gaming": true,
        "nix-dev": true
      }
    '';
  };
}

