{
  pkgs,
  inputs,
  ...
}:
{
  # Note: DOTS framework provides Home Manager modules only
  # DOTS features are enabled per-user in home configurations
  
  # System-wide support for DOTS framework
  # (programs.light.enable is already defined above)
  
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
    enable = false;
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
