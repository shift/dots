_: {
  system.nixos.distroId = "dots";
  # Stops systemd from blocking booting if a service hangs while activating.
  systemd.extraConfig = ''
    DefaultTimeoutStopSec=10s
  '';
  # Blocks on some hardware, so lets just disable it.
  systemd.services.NetworkManager-wait-online.enable = false;

  systemd.services.systemd-logind.environment = {
    SYSTEMD_BYPASS_HIBERNATION_MEMORY_CHECK = "1";
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };

  programs.dconf.enable = true;
  programs.light.enable = true;

  users.groups = {
    children = {
      name = "children";
    };
  };

}
