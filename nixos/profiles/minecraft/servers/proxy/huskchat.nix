{ pkgs, ... }:
{
  services.minecraft-servers.servers.proxy = {
    extraReload = ''
      echo 'huskchat reload' > /run/minecraft/proxy.sock
    '';
    symlinks = {
      "plugins/HuskChat.jar" = pkgs.fetchurl rec {
        pname = "HuskChat";
        version = "2.7.1";
        url = "https://github.com/WiIIiam278/${pname}/releases/download/${version}/${pname}-${version}.jar";
        hash = "sha256-Vg0xu2Z7WeeabK1r5qOw9STcK9kxA5ApshljyXDUy7M=";
      };
      "plugins/UnSignedVelocity.jar" = pkgs.fetchurl rec {
        pname = "UnSignedVelocity";
        version = "1.4.2";
        url = "https://github.com/4drian3d/${pname}/releases/download/${version}/${pname}-${version}.jar";
        hash = "sha256-i6S05M4mGxnp4tJmR4AKFOBgEQb7d5mTH95nryA7v0A=";
      };
      "plugins/VPacketEvents.jar" = pkgs.fetchurl rec {
        pname = "VPacketEvents";
        version = "1.1.0";
        url = "https://github.com/4drian3d/${pname}/releases/download/${version}/${pname}-${version}.jar";
        hash = "sha256-qWHR8hn56vf8csUDhuzV8WPBhZtaJE+uLNqupcJvGEI=";
      };
    };
    files = {
      "plugins/huskchat/config.yml".value = {
        config-version = 2;
        check_for_updates = false;
        default_channel = "default";
        channel_log_format = "[CHAT] [%channel%] %sender%: ";
        channel_command_aliases = [
          "/channel"
          "/c"
        ];

        channels = {
          default = {
            broadcast_scope = "GLOBAL";
            log_to_console = true;
            shortcut_commands = [
              "/global"
              "/g"
              "/default"
              "/d"
            ];
          };
          internal = {
            broadcast_scope = "PASSTHROUGH";
            shortcut_commands = [
              "/i"
              "/internal"
            ];
          };
        };
        broadcast_command = {
          enabled = true;
          broadcast_aliases = [
            "/broadcast"
            "/alert"
          ];
          log_to_console = true;
          log_format = "[SERVER]: ";
        };
        message_command = {
          enabled = true;
          msg_aliases = [
            "/msg"
            "/m"
            "/tell"
            "/whisper"
            "/w"
            "/pm"
          ];
          reply_aliases = [
            "/reply"
            "/r"
          ];
          log_to_console = true;
          log_format = "[MSG] [%sender% -> %receiver%]: ";
          group_messages.enabled = false;
          format = {
            inbound = "&#00fb9a&%name% &8→ &#00fb9a&Você&8: &f";
            outbound = "&#00fb9a&Você &8→ &#00fb9a&%name%&8: &f";
          };
        };
        social_spy.enabled = false;
        local_spy.enabled = false;
        chat_filters = {
          advertising_filter.enabled = false;
          caps_filter.enabled = false;
          spam_filter.enabled = false;
          profanity_filter.enabled = false;
          repeat_filter.enabled = false;
          ascii_filter.enabled = false;
        };
        message_replacers.emoji_replacer.enabled = false;
        discord.enabled = false;
        join_and_quit_messages = {
          join = {
            enabled = true;
          };
          quit = {
            enabled = true;
          };
          broadcast_scope = "GLOBAL";
        };
      };
    };
  };
}
