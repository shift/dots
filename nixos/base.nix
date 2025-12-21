{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    # Completely disable all dots-framework modules until technical issues are resolved
    # inputs.dots.nixosModules.default
  ];
  
  # Enable dynamic waybar system-wide (temporarily disabled due to syntax issues)
  # features.dynamic-waybar.enable = true;
  # features.dynamic-waybar.deviceType = "laptop";
  # features.dynamic-waybar.hardware.battery = "BAT0";
  # features.dynamic-waybar.hardware.networkInterface = "wlan0";
  
  # Configure waybar priority overrides for optimal layout
  # features.dynamic-waybar.priorityOverrides = {
  #   "custom/media" = 40;
  #   "network" = 230;
  #   "battery" = 310;
  #   "clock" = 320;
  #   "tray" = 330;
  # };
  
  # Enable hardware detection module for better device support
  #features.dynamic-hardware.facter.enable = true;
  
  system.nixos.distroId = "dots";
  # Stops systemd from blocking booting if a service hangs while activating.
  systemd.settings.Manager = {
    DefaultTimeoutStopSec = "10s";
  };
  # Blocks on some hardware, so lets just disable it.
  systemd.services.NetworkManager-wait-online.enable = false;

  systemd.services.systemd-logind.environment = {
    SYSTEMD_BYPASS_HIBERNATION_MEMORY_CHECK = "1";
  };

  services.system-notifier.enable = true;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };

  services.geoclue-prometheus-exporter = {
    enable = true;
    bind = "127.0.0.1";
    port = 9090;
    openFirewall = false;
  };

  programs.dconf.enable = true;
  programs.light.enable = true;

  users.groups = {
    children = {
      name = "children";
    };
  };
  environment.systemPackages = with pkgs; [
    gnome-software
    gnome-calculator
    gnome-calendar
    gnome-screenshot
    firefox
    flatpak
    xdg-desktop-portal
    xdg-desktop-portal-gtk
    xdg-desktop-portal-gnome
    system-config-printer
  ];
}
