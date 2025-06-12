{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mapAttrs' replaceStrings nameValuePair;
in
{
  services.minecraft-servers.servers.proxy = {
    symlinks."plugins/LibreLogin.jar" = pkgs.fetchurl rec {
      pname = "LibreLogin";
      version = "0.18.3";
      url = "https://github.com/kyngs/${pname}/releases/download/${version}/${pname}.jar";
      hash = "sha256-n4np9Q4Ej3UMk314ozVc0idgaGzFBuLaZ0kRx7BfqxI=";
    };
    files = {
      "plugins/librelogin/config.conf".format = pkgs.formats.json { };
      "plugins/librelogin/config.conf".value = {
        allowed-commands-while-unauthorized = [
          "login"
          "register"
          "2fa"
          "2faconfirm"
        ];
        auto-register = false;
        database = {
          database = "minecraft";
          host = "localhost";
          max-life-time = 600000;
          password = "@DATABASE_PASSWORD@";
          port = 3306;
          user = "minecraft";
        };
        debug = false;
        default-crypto-provider = "BCrypt-2A";
        fallback = false;
        kick-on-wrong-password = false;
        limbo = [ "limbo" ];
        migration = { };
        milliseconds-to-refresh-notification = 10000;
        minimum-password-length = -1;
        new-uuid-creator = "MOJANG";
        # Use the same config as velocity's "try" and "forced-hosts
        pass-through =
          let
            velocityCfg = config.services.minecraft-servers.servers.proxy.files."velocity.toml".value;
          in
          {
            root = velocityCfg.servers.try;
          }
          // (mapAttrs' (n: nameValuePair (replaceStrings [ "." ] [ "§" ] n)) velocityCfg.forced-hosts);
        ping-servers = true;
        remember-last-server = true;
        revision = 3;
        seconds-to-authorize = -1;
        session-timeout = 604800;
        totp.enabled = true;
        use-titles = false;
      };
    };
  };
}
