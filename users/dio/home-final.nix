# Final Working DOTS Framework Configuration for dio User
{ pkgs, inputs', ... }:
{
  imports = [
    # Use working DOTS modules
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

  # Stylix configuration (fixed warnings)
  stylix = {
    enable = true;
    autoEnable = true;
    image = ../../assets/dio/wallpaper.png;
    targets = {
      firefox.profileNames = [ "default" ];
      grub.useWallpaper = true;
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

  # Zsh shell configuration with DOTS aliases (fixed warnings)
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;  # Fixed renamed option
    syntaxHighlighting.enable = true;
    shellAliases = {
      ll = "ls -la";
      la = "ls -a";
      l = "ls -l";
      g = "git";
      cls = "clear";
    };
  };

  # Niri window manager configuration (using system package)
  home.packages = with pkgs; [
    inputs.niri.packages.${stdenv.hostPlatform.system}.niri
  ];

  # Optional: Add niri settings if you want them in home manager
  # Note: niri is typically configured system-wide via NixOS config

  home.stateVersion = "25.05";
  programs.home-manager.enable = true;
}