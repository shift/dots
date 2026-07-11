{ config
, lib
, pkgs
, options
, inputs'
, ...
}:
{
    imports = [
      inputs'.nixvim.homeModules.nixvim
      #inputs'.dots.homeManagerModules.default
      inputs'.dots.homeManagerModules.dynamic-aliases
      inputs'.dots.homeManagerModules.dynamic-fonts
      inputs'.dots.homeManagerModules.dynamic-environment
      inputs'.dots.homeManagerModules.dynamic-shell-suite
      inputs'.dots.homeManagerModules.dynamic-starship
      inputs'.dots.homeManagerModules.dynamic-autostart
      inputs'.dots.homeManagerModules.dynamic-notifications
      inputs'.dots.homeManagerModules.dynamic-keys
      inputs'.dots.homeManagerModules.dynamic-profiles
      inputs'.dots.homeManagerModules.dynamic-ssh
      inputs'.dots.homeManagerModules.dynamic-mime
      inputs'.dots.homeManagerModules.dynamic-help
      inputs'.dots.homeManagerModules.dynamic-input
      inputs'.dots.homeManagerModules.dynamic-state
      inputs'.dots.homeManagerModules.dynamic-timers
      inputs'.dots.homeManagerModules.dynamic-secrets # Now using enhanced upstream version
      inputs'.dots.homeManagerModules.dynamic-waybar # Full dynamic-waybar implementation with widget management
      inputs'.dots.homeManagerModules.dynamic-hardware # Enable with waybar stub
      # inputs.dots.homeManagerModules.dynamic-security # Security hardening suite - not yet available in upstream
      ./niri.nix
    ];

  stylix = {
    enable = true;
    autoEnable = true;
    image = ../../assets/dio/wallpaper.png;
    targets = {
      firefox.profileNames = [ "default" ];
    };
  };



    # Enable dots framework features
    features.dynamic-aliases.enable = true;
    features.dynamic-fonts.enable = true;
    features.dynamic-environment.enable = true;
    features.dynamic-shell-suite.enable = true;
    features.dynamic-starship.enable = true;
    features.dynamic-autostart.enable = true;
    features.dynamic-notifications.enable = true;
    features.dynamic-keys.enable = true;
    features.dynamic-ssh.enable = true;
    features.dynamic-mime.enable = true;
    features.dynamic-help.enable = true;
    features.dynamic-input.enable = true;
    features.dynamic-state.enable = true;
    features.dynamic-timers.enable = true;
    features.dynamic-secrets.enable = true; # Now using fixed version
    # features.dynamic-security = {
    #   enable = true;
    #   profile = "balanced"; # Good security with reasonable convenience
    # };
    features.dynamic-waybar = {
      enable = true;
      theme = "cyberpunk";
      disabledWidgets = [
        "custom/launchers"
        "custom/gammastep"
        "custom/uptime"
        "custom/nix_store"
        "custom/tailscale"
        "custom/flake-age"
        "custom/nix-monitor"
        "custom/nixos_gen"
        "custom/nixos_version"
        "custom/nix_store"
        "custom/system_failed"
        "custom/nix_build"
        "custom/mullvad"
        "custom/docker"
        "custom/podman"
        "custom/cliphist"
        "custom/dunst"
        "custom/docker"
        "custom/podman"
        "custom/github"
        "custom/profile-rust"
        "custom/profile-python"
        "custom/profile-web"
        "custom/libvirt"
        "custom/syncthing"
        "custom/taskwarrior"
        "custom/swaync"
        "custom/flatpak"
	"custom/disk-usage"
        "custom/usb"
        "custom/nix_gc"
        "custom/github"
        "custom/systemd"
        "custom/trash"
        "custom/process-count"
        "custom/system-updates"
        "custom/colorpicker"
        "custom/cpu-usage"
        "custom/easyeffects"
        "custom/hyprshade"
        #"custom/launcher"
        "custom/media"
        "custom/memory-usage"
        "custom/network-monitor"
        "custom/power"
        #"custom/reboot_required"
        "custom/recorder"
        "custom/screenshot"
	"temperature"
        "custom/usbguard"
        #"custom/launcher"
        "custom/media"
        "custom/recorder"
        #"custom/colorpicker"
        "custom/hyprshade"
        #"custom/screenshot"
        "custom/easyeffects"
        "custom/usbguard"
        "custom/cpu-usage"
        "custom/network-monitor"
        "keyboard-state"
        #"battery#bat2"
	"image"
      ];
    };
    features.dynamic-hardware.enable = true; # Now enabled with waybar stub






 # Resolve theme conflicts - let Stylix take precedence
    programs.bat.config.theme = lib.mkForce "base16-stylix";
    programs.btop.settings.color_theme = lib.mkForce "stylix";

  home.stateVersion = "25.05"; # Don't change this. This will not upgrade your home-manager.
  programs.home-manager.enable = true;

  #### You can edit this below here

  programs.firefox.enable = true;
  programs.vscode = {
    enable = true;
    userSettings = {
      "window.titleBarStyle" = "custom";
    };
  };
  home.packages = with pkgs; [
    reaper # Music editing software
    davinci-resolve # Video editing software
    vlc # video player
    bitwarden-desktop
    ghostty
    wasistlos
  ];

}
