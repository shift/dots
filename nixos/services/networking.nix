{
  lib,
  ...
}:
{
  # Networking configuration
  networking = {
    hostName = lib.mkDefault "nixos"; # Override in host-specific config
    wireless.dbusControlled = true;
    networkmanager = {
      enable = true;
    };
  };

  # Firewall configuration
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };

  # Avahi for network discovery
  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };

  # Tailscale VPN
  services.tailscale = {
    enable = lib.mkDefault false; # Enable in host-specific config if needed
    useRoutingFeatures = "both";
    extraUpFlags = [
      "--ssh"
      "--advertise-exit-node"
      "--exit-node"
    ];
  };
}
