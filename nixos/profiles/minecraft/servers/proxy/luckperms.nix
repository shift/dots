{ pkgs, lib, ... }:
{
  services.minecraft-servers.servers.proxy = rec {
    extraReload = ''
      echo 'lpv import initial.json.gz' > /run/minecraft/proxy.sock
    '';

    symlinks = {
      "plugins/LuckPerms.jar" =
        let
          build = "1532";
        in
        pkgs.fetchurl rec {
          pname = "LuckPerms";
          version = "5.4.119";
          url = "https://download.luckperms.net/${build}/velocity/${pname}-Velocity-${version}.jar";
          hash = "sha256-afodd3H1vArkOflQRNg46J5N87WMDM7NJw8Sn9ShSI0=";
        };
      "plugins/luckperms/initial.json.gz".format = pkgs.formats.gzipJson { };
      "plugins/luckperms/initial.json.gz".value =
        let
          mkPermissions = lib.mapAttrsToList (key: value: { inherit key value; });
        in
        {
          groups = {
            owner.nodes = mkPermissions {
              "group.admin" = true;
              "prefix.1000.&5" = true;
              "weight.1000" = true;

              "librelogin.*" = true;
              "luckperms.*" = true;
              "velocity.command.*" = true;
            };
            admin.nodes = mkPermissions {
              "group.default" = true;
              "prefix.900.&6" = true;
              "weight.900" = true;

              "huskchat.command.broadcast" = true;
            };
            default.nodes = mkPermissions {
              "huskchat.command.channel" = true;
              "huskchat.command.msg" = true;
              "huskchat.command.msg.reply" = true;
            };
          };
          users = {
            "00000000-0000-0000-0009-01fd7182eedc" = {
              username = ".TotallySectione";
              nodes = mkPermissions {
                "group.owner" = true;
              };
            };
            "00000000-0000-0000-0009-01f1cd6bf4f1" = {
              username = ".DioDioDio123";
              nodes = mkPermissions {
                "group.admin" = true;
              };
            };
          };
        };
    };

    files = {
      "plugins/luckperms/config.yml".value = {
        server = "proxy";
        storage-method = "mysql";
        data = {
          address = "127.0.0.1";
          database = "minecraft";
          username = "minecraft";
          password = "@DATABASE_PASSWORD@";
          table-prefix = "luckperms_";
        };
        messaging-service = "sql";
      };
    };
  };
}
