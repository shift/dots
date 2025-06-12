{ pkgs, ... }:
{
  imports = [
    ## Modularize your home.nix by moving statements into other files
  ];

  home.stateVersion = "25.05"; # Don't change this. This will not upgrade your home-manager.
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    # Common packages
    hello
  ];
}
