{
  config,
  lib,
  ...
}:
{
  imports = [
    # Basic system modules
    ../nixos/nix.nix
    ../nixos/base.nix
    ../nixos/system.nix
    ../nixos/i18n.nix
    ../nixos/fontconfig.nix
    ../nixos/persistence.nix
    ../nixos/current-location.nix

    # Hardware modules
    ../nixos/hardware/boot.nix
    ../nixos/hardware/laptop.nix

    # Service modules
    ../nixos/services/networking.nix
    ../nixos/services/audio-print.nix
    ../nixos/sshd.nix

    # Desktop modules
    ../nixos/desktop/sway.nix
    ../nixos/desktop/services.nix

    # Security and users
    ../nixos/security.nix
    ../nixos/users.nix

    # Additional packages
    ../nixos/packages.nix
  ];

  # Host-specific configuration
  networking.hostName = "shulkerbox";

  # Set timezone for Berlin
  time.timeZone = "Europe/Berlin";
  location.provider = "geoclue2";

  # SOPS secrets configuration
  sops.defaultSopsFile = ../secrets/common.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.secrets.grafana_api_token = { };
  sops.secrets."shift_hashed_passwd" = {
    neededForUsers = true;
  };
  sops.secrets."shift_ssh_key" = {
    neededForUsers = true;
  };
  sops.secrets."cachix_api_key" = {
    neededForUsers = true;
  };
  sops.secrets."dio_hashed_passwd" = {
    neededForUsers = true;
    sopsFile = ./../secrets/shulkerbox/secrets.yaml;
  };
  sops.secrets."squeals_hashed_passwd" = {
    neededForUsers = true;
    sopsFile = ./../secrets/shulkerbox/secrets.yaml;
  };

  # Enable host-specific services
  services.tailscale.enable = true;
  security.pam.yubico.enable = true;
  programs.steam.enable = true;
  programs.gamescope.enable = true;
  virtualisation.podman.enable = true;
  services.flatpak.enable = true;
  services.xserver.desktopManager.cinnamon.enable = true;

  # Override some defaults for this host
  nix.settings.max-jobs = lib.mkForce 1; # Laptop-specific optimization

  # Allow unfree packages for this host
  nixpkgs.config.allowUnfree = true;

  # Home manager configuration
  home-manager.backupFileExtension = "backup";
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.shift = ./../users/shift/home.nix;
  home-manager.users.dio = ./../users/dio/home.nix;
  home-manager.users.squeals = ./../users/squeals/home.nix;

  # Monitoring configuration
  services.grafana-alloy-laptop = {
    enable = true;
    grafanaCloud = {
      url = "https://prometheus-prod-24-prod-eu-west-2.grafana.net/api/prom/push";
      username = "1842292";
      password = config.sops.secrets.grafana_api_token;
    };
    textfileCollector.enable = true;
  };

  services.geoclue-prometheus-exporter = {
    enable = true;
    bind = "127.0.0.1";
    port = 9090;
  };

  # SSH deny groups
  services.openssh.settings.DenyGroups = [ "children" ];

  system.stateVersion = "25.05";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
