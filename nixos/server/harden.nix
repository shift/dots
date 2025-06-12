{ flake, ... }:
{

  # Firewall
  networking.firewall.enable = true;

  security.sudo.execWheelOnly = true;

  security.sudo.wheelNeedsPassword = false;
  users.users.${flake.config.people.myself} = {
    extraGroups = [ "wheel" ];
  };

  security.auditd.enable = true;
  security.audit.enable = true;

  services = {
    openssh = {
      enable = true;
      settings.PermitRootLogin = "prohibit-password"; # distributed-build.nix requires it
      settings.PasswordAuthentication = false;
      allowSFTP = false;
    };
    fail2ban = {
      enable = true;
      ignoreIP = [
        "192.168.1.0/24"
        "10.0.0.0/8"
      ];
    };
  };
  nix.settings.allowed-users = [
    "root"
    "@users"
  ];
}
