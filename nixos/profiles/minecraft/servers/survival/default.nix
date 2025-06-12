{ pkgs, ... }:
{
  services.minecraft-servers.servers.survival = {
    enable = true;
    enableReload = true;
    package = pkgs.paperServers.paper-1_20_4;
    jvmOpts = ((import ../../aikar-flags.nix) "2G") + "-Dpaper.disableChannelLimit=true";
    serverProperties = {
      server-port = 25571;
      online-mode = false;
    };
    files = {
      "config/paper-global.yml".value = {
        proxies.velocity = {
          enabled = true;
          online-mode = false;
          secret = "@VELOCITY_FORWARDING_SECRET@";
        };
      };
      "bukkit.yml".value = {
        settings.shutdown-message = "Shutting down...";
      };
      "spigot.yml".value = {
        messages = {
          whitelist = "Whitelisted.";
          unknown-command = "Nice try, but I don't know that, check it's bee spelt correctly.";
          restart = "Restarting...";
        };
      };
      "plugins/ViaVersion/config.yml".value = {
        checkforupdates = false;
      };
      "plugins/LuckPerms/config.yml".value = {
        server = "survival";
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
    symlinks = {
      "plugins/ViaVersion.jar" = pkgs.fetchurl rec {
        pname = "ViaVersion";
        version = "4.8.0";
        url = "https://github.com/ViaVersion/${pname}/releases/download/${version}/${pname}-${version}.jar";
        hash = "sha256-VHvFMbiA8clgrlpfCNzqlzs/QSVN60Yt6h63KI3w6ns=";
      };
      "plugins/ViaBackwards.jar" = pkgs.fetchurl rec {
        pname = "ViaBackwards";
        version = "4.8.0";
        url = "https://github.com/ViaVersion/${pname}/releases/download/${version}/${pname}-${version}.jar";
        hash = "sha256-JSE71YbivWCqUzNwPVFNgqlhhFkMoIstrn+L/F3qdFM=";
      };
      "plugins/LuckPerms.jar" =
        let
          build = "1532";
        in
        pkgs.fetchurl rec {
          pname = "LuckPerms";
          version = "5.4.119";
          url = "https://download.luckperms.net/${build}/bukkit/loader/${pname}-Bukkit-${version}.jar";
          hash = "sha256-afodd3H1vArkOflQRNg46J5N87WMDM7NJw8Sn9ShSI0=";
        };
      "plugins/HidePLayerJoinQuit.jar" = pkgs.fetchurl rec {
        pname = "HidePLayerJoinQuit";
        version = "1.0";
        url = "https://github.com/OskarZyg/${pname}/releases/download/v${version}-full-version/${pname}-${version}-Final.jar";
        hash = "sha256-UjLlZb+lF0Mh3SaijNdwPM7ZdU37CHPBlERLR3LoxSU=";
      };
    };
  };
}
