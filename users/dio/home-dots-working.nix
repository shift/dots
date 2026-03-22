# Working Configuration for dio User - Using DOTS Framework Successfully
{ pkgs, inputs', ... }:
{
  imports = [
    # Use only basic working DOTS modules that are tested
    inputs'.dots.homeManagerModules.dynamic-aliases
  ];

  # DOTS Framework modules - working configuration
  features = {
    dynamic-aliases = {
      enable = true;
      aliases = [
        { alias = "ll"; command = "ls -la"; }
        { alias = "la"; command = "ls -a"; }
        { alias = "l"; command = "ls -l"; }
        { alias = "g"; command = "git"; }
        { alias = "cls"; command = "clear"; }
      ];
    };
  };

  # Essential packages
  home.packages = with pkgs; [
    reaper # Music editing software
    davinci-resolve # Video editing software
    vlc # video player
    # Essential niri/wayland packages
    fuzzel
    alacritty
    foot
    starship
    playerctl
    tree
    pavucontrol
    slurp
    grim
    swww
    wshowkeys
    swaynotificationcenter
    wl-clipboard
    light
    pamixer
    swaylock
    networkmanagerapplet
    udiskie
    jami
    steam
  ];

  # Stylix configuration
  stylix = {
    enable = true;
    autoEnable = true;
    image = ../../assets/dio/wallpaper.png;
    targets = {
      firefox.profileNames = [ "default" ];
    };
  };

  # Starship prompt configuration
  programs.starship = {
    enable = true;
    settings = {
      format = "$all";
      right_format = "";
    };
  };

  # Zsh shell configuration with DOTS aliases
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableAutosuggestions = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      ll = "ls -la";
      la = "ls -a";
      l = "ls -l";
      g = "git";
      cls = "clear";
    };
  };

  home.stateVersion = "25.05";
  programs.home-manager.enable = true;
}