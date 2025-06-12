{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./servers/proxy
    ./servers/limbo
    ./servers/lobby
    ./servers/survival
    # Disabled for now, while I work out some issues with the mods
    # ./servers/modpack
  ];

  sops.secrets.minecraft-secrets = {
    owner = "minecraft";
    group = "minecraft";
    mode = "0440";
    # VELOCITY_FORWARDING_SECRET, DATABASE_PASSWORD
    sopsFile = ./secrets.yaml;
    format = "yaml";
  };
  services.minecraft-servers = {
    enable = true;
    eula = true;
    environmentFile = config.sops.secrets.minecraft-secrets.path;
    dataDir = "/opt/minecraft";
  };

  networking.firewall = {
    allowedTCPPorts = [ 25565 ];
    allowedUDPPorts = [
      25565
      19132
    ];
  };

  services.mysql = {
    package = pkgs.mariadb;
    enable = true;
    ensureDatabases = [ "minecraft" ];
    ensureUsers = [
      {
        name = "minecraft";
        ensurePermissions = {
          "minecraft.*" = "ALL PRIVILEGES";
        };
      }
    ];
  };
  # Set minecrafts' password (the plugins don't play well with socket auth)
  users.users.mysql.extraGroups = [ "minecraft" ]; # Get access to the secret
  systemd.services.mysql.postStart = lib.mkAfter ''
    source ${config.sops.secrets.minecraft-secrets.path}
    ${config.services.mysql.package}/bin/mysql <<EOF
      ALTER USER 'minecraft'@'localhost'
        IDENTIFIED VIA unix_socket OR mysql_native_password
        USING PASSWORD('$DATABASE_PASSWORD');
    EOF
  '';
}
