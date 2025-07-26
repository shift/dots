{
  lib,
  pkgs,
  ...
}:
{
  # Gaming-related configuration
  programs.steam.enable = lib.mkDefault false;
  programs.gamescope.enable = lib.mkDefault false;

  # Virtualization
  virtualisation.podman.enable = lib.mkDefault false;

  # Flatpak support
  services.flatpak.enable = lib.mkDefault false;

  # Various desktop services
  services = {
    journald.extraConfig = ''
      SystemMaxUse=256M
    '';

    tumbler.enable = true; # Thumbnail generation
    acpid.enable = true; # ACPI daemon

    dbus = {
      enable = true;
      implementation = "broker";
      packages = [
        pkgs.gcr
      ];
    };

    accounts-daemon.enable = true;
    blueman.enable = lib.mkDefault true; # Bluetooth manager
    fwupd.enable = true; # Firmware updater
    udisks2.enable = true; # Disk management
    upower.enable = true; # Power management
  };

  # Additional desktop packages
  environment.systemPackages = with pkgs; [
    gsettings-desktop-schemas
    showmethekey
    libGL
  ];
}
