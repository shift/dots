{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.shift.waybar;
  terminal = "${pkgs.foot}/bin/footclient";
  systemMonitor = "${terminal} htop";
  colours = config.lib.stylix.colors;
in
{
  options.shift.waybar = {
    enable = mkEnableOption "";
  };

  config = mkIf cfg.enable {
    programs.waybar = {
      enable = true;
      style =
        ''
                  * {
          	    font-family: "Fira Code", "Font Awesome 6 Free Solid", "Font Awesome 6 Brands", "Symbols Nerd Font";
                      border: none;
                      border-radius: 0 0 10px 10px;
                      font-size: 15px;
                      min-height: 10px;
                  }
        ''
        + (builtins.readFile ./style.css);

      settings = {
        "bar-0" = {
          layer = "top";
          position = "top";
          height = 24;
          width = null;
          exclusive = true;
          passthrough = false;
          spacing = 4;
          margin = null;
          margin-top = 0;
          margin-bottom = 0;
          margin-left = 0;
          margin-right = 0;
          fixed-center = true;
          ipc = true;

          # Modules display
          modules-left = [
            "sway/workspaces"
          ];
          modules-center = [
            "custom/waybar-mpris"
            "sway/language"
          ];
          modules-right = [
            "idle_inhibitor"
            "network"
            "cpu"
            "memory"
            "pulseaudio"
            "backlight"
            "bluetooth"
            "battery"
            "clock"
            "tray"
          ];

          # Modules
          "custom/waybar-mpris" = {
            return-type = "json";
            exec = "waybar-mpris --position --autofocus";
            on-click = "waybar-mpris --send toggle";
            on-click-right = "waybar-mpris --send player-next";
            on-scroll-up = "waybar-mpris --send next";
            on-scroll-down = "waybar-mpris --send prev";
            escape = true;
          };

          "sway/language" = {
            format = "{short} {variant}";
            on-click = "swaymsg input type:keyboard xkb_switch_layout next";
          };

          idle_inhibitor = {
            format = "{icon}";
            format-icons = {
              activated = "";
              deactivated = "";
            };
          };
          bluetooth = {
            format = " {status}";
            format-connected = " {device_alias}";
            format-connected-battery = " {device_alias} {device_battery_percentage}%";
            tooltip-format = "{controller_alias}\t{controller_address}\n\n{num_connections} connected";
            tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}";
            tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
            tooltip-format-enumerate-connected-battery = "{device_alias}\t{device_address}\t{device_battery_percentage}%";
          };

          pulseaudio = {
            format = "{icon} {volume}%";
            format-muted = " Mute";
            format-bluetooth = " {volume}% {format_source}";
            format-bluetooth-muted = " Mute";
            format-source = " {volume}%";
            format-source-muted = "";
            format-icons = {
              headphone = "";
              hands-free = "";
              headset = "";
              phone = "";
              portable = "";
              car = "";
              default = [
                ""
                ""
                ""
              ];
            };
            scroll-step = 5.0;
            on-click = "pamixer --toggle-mute";
            on-click-right = "pwvucontrol";
            smooth-scrolling-threshold = 1;
          };
          network = {
            format-wifi = " {essid}";
            format-ethernet = " {essid}";
            format-linked = "{ifname} (No IP) ";
            format-disconnected = "睊";
            tooltip = true;
            tooltip-format = ''
              {ifname}
              {ipaddr}/{cidr}
              Up: {bandwidthUpBits}
              Down: {bandwidthDownBits}'';
          };
          cpu = {
            format = "{icon0}{icon1}{icon2}{icon3}{icon4}{icon5}{icon6}{icon7}";
            format-icons = [
              "<span color='#69ff94'>▁</span>"
              "<span color='#2aa9ff'>▂</span>"
              "<span color='#f8f8f2'>▃</span>"
              "<span color='#f8f8f2'>▄</span>"
              "<span color='#ffffa5'>▅</span>"
              "<span color='#ffffa5'>▆</span>"
              "<span color='#ff9977'>▇</span>"
              "<span color='#dd532e'>█</span>"
            ];
            on-click = systemMonitor;
          };
          memory = {
            format = "{icon} {used:0.1f}G/{total:0.1f}G";
            interval = 5;
            on-click = systemMonitor;
          };
          backlight = {
            interval = 2;
            align = 0;
            rotate = 0;
            #"device": "amdgpu_bl0",
            format = "{icon} {percent}%";
            format-icons = [
              ""
              ""
              ""
              ""
            ];
            on-click = "";
            on-click-middle = "";
            on-click-right = "";
            on-update = "";
            on-scroll-up = "brightnessctl s 5%+";
            on-scroll-down = "brightnessctl s 5%";
            smooth-scrolling-threshold = 1;
          };
          battery = {
            interval = 60;
            align = 0;
            rotate = 0;
            full-at = 100;
            design-capacity = false;
            states = {
              good = 80;
              warning = 30;
              critical = 15;
            };
            format = "{icon}  {capacity}%";
            format-charging = " {capacity}%";
            format-plugged = "  {capacity}%";
            format-full = "{icon}  Full";
            # format-good = "";
            format-alt = "{icon} {time}";
            format-icons = [
              ""
              ""
              ""
              ""
              ""
            ];
            format-time = "{H}h {M}min";
            tooltip = true;
          };
          clock = {
            interval = 60;
            align = 0;
            rotate = 0;
            tooltip-format = "<big>{:%B %Y}</big>\n<tt><small>{calendar}</small></tt>";
            format = " {:%I:%M %p}";
            format-alt = " {:%a %b %d, %G}";
            calendar = {
              mode = "year";
              mode-mon-col = 3;
              weeks-pos = "right";
              on-scroll = 1;
              format = {
                months = "<span color='#ffead3'><b>{}</b></span>";
                days = "<span color='#ecc6d9'><b>{}</b></span>";
                weeks = "<span color='#99ffdd'><b>W{}</b></span>";
                weekdays = "<span color='#ffcc66'><b>{}</b></span>";
                today = "<span color='#ff6699'><b><u>{}</u></b></span>";
              };
            };
            actions = {
              on-click-right = "mode";
              on-click-forward = "tz_up";
              on-click-backward = "tz_down";
              on-scroll-up = "shift_up";
              on-scroll-down = "shift_down";
            };
          };
          tray = {
            icon-size = 14;
            spacing = 6;
          };
        };
      };
    };
    home.file.".config/waybar/colours.css".text =
      ''@define-color base00 #''
      + colours.base00
      + ''
        ;
            @define-color base01 #''
      + colours.base01
      + ''
        ;
            @define-color base02 #''
      + colours.base02
      + ''
        ;
            @define-color base03 #''
      + colours.base03
      + ''
        ;
            @define-color base04 #''
      + colours.base04
      + ''
        ;
            @define-color base05 #''
      + colours.base05
      + ''
        ;
            @define-color base06 #''
      + colours.base06
      + ''
        ;
            @define-color base07 #''
      + colours.base07
      + ''
        ;
            @define-color base08 #''
      + colours.base08
      + ''
        ;
            @define-color base09 #''
      + colours.base09
      + ''
        ;
            @define-color base0A #''
      + colours.base0A
      + ''
        ;
            @define-color base0B #''
      + colours.base0B
      + ''
        ;
            @define-color base0C #''
      + colours.base0C
      + ''
        ;
            @define-color base0D #''
      + colours.base0D
      + ''
        ;
            @define-color base0E #''
      + colours.base0E
      + ''
        ;
            @define-color base0F #''
      + colours.base0F
      + ''
        ;
      '';
  };
}
