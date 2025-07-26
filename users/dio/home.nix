{ pkgs, ... }:
{
  imports = [
    ## Modularize your home.nix by moving statements into other files
  ];
  stylix = {
    enable = true;
    autoEnable = true;
    image = ../../assets/dio/wallpaper.png;
    targets = {
      firefox.profileNames = [ "default" ];
    };
  };
  home.stateVersion = "25.05"; # Don't change this. This will not upgrade your home-manager.
  programs.home-manager.enable = true;

  #### You can edit this below here

  programs.firefox.enable = true;
  programs.vscode = {
    enable = true;
    profiles = {
      default = {
        userSettings = {
          "window.titleBarStyle" = "custom";
        };
      };
    };
  };
  home.packages = with pkgs; [
    reaper # Music editing software
    davinci-resolve # Video editing software
  ];
}
