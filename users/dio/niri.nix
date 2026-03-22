{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./fuzzel.nix
    ./swaylock.nix
  ];

  config = {
    # Note: programs.niri is enabled at system level, this provides user-specific configuration
    programs.niri = {
      settings = {
        input = {
          keyboard = {
            xkb = {
              layout = "us,de";
              options = "eurosign:e,ctrl:nocaps,grp:alt_shift_toggle";
            };
          };

          touchpad = {
            tap = true;
            natural-scroll = true;
            click-method = "clickfinger";
            scroll-method = "two-finger";
            dwt = true;
          };

          tablet = {
            map-to-output = "eDP-1";
          };
        };

        layout = {
          gaps = 3;
          center-focused-column = "never";
          preset-column-widths = [
            { proportion = 0.33333; }
            { proportion = 0.5; }
            { proportion = 0.66667; }
          ];
          default-column-width = {
            proportion = 0.5;
          };

          focus-ring = {
            enable = true;
            width = 2;
          };

          border = {
            enable = true;
            width = 2;
          };

          struts = {
            left = 16;
            right = 16;
            top = 32;
            bottom = 32;
          };
        };

        spawn-at-startup = [
          # Critical for immediate visual feedback
          {
            argv = [
              "${pkgs.swww}/bin/swww-daemon"
            ];
          }
          {
            argv = [
              "sh"
              "-c"
              "${pkgs.swww}/bin/swww img ${
                if config ? stylix && config.stylix ? image && config.stylix.image != null then
                  config.stylix.image
                else
                  ./wallpaper/default.jpg
              } --transition-type simple --transition-duration 0"
            ];
          }
          {
            argv = [
              "sh"
              "-c"
              "if niri msg outputs | grep -q 'DP-3'; then waybar --output DP-3; else waybar --output eDP-1; fi"
            ];
          }

          # Deferred startup - less critical, can load async
	  {
            argv = [
              "sh"
              "-c"
              "sleep 0.5 && ${pkgs.jami}/bin/jami"
            ];
          }
          {
            argv = [
              "sh"
              "-c"
              "sleep 0.5 && ${pkgs.networkmanagerapplet}/bin/nm-applet"
            ];
          }
          {
            argv = [
              "sh"
              "-c"
              "sleep 0.5 && ${pkgs.swaynotificationcenter}/bin/swaync"
            ];
          }
          {
            argv = [
              "sh"
              "-c"
              "sleep 0.5 && ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
            ];
          }
          {
            argv = [
              "sh"
              "-c"
              "sleep 1 && ${pkgs.crystal-dock}/bin/crystal-dock"
            ];
          }
          {
            argv = [
              "sh"
              "-c"
              "sleep 0.3 && ${pkgs.udiskie}/bin/udiskie --tray"
            ];
          }
          {
            argv = [
              "${pkgs.gnupg}/bin/gpgconf"
              "--launch"
              "gpg-agent"
            ];
          }
          {
            argv = [
              "systemctl"
              "--user"
              "import-environment"
              "SSH_AUTH_SOCK"
            ];
          }
          {
            argv = [
              "wl-paste"
              "-t"
              "text"
              "--watch"
              "clipman"
              "store"
              "--no-persist"
            ];
          }
          {
            argv = [
              "wlsunset"
              "-l"
              "49.1113"
              "-L"
              "9.73908"
            ];
          }
        ];

        prefer-no-csd = true;

        screenshot-path = "~/Pictures/screenshot-%Y-%m-%d-%H-%M-%S.png";

        workspaces = {
          "web" = { };
          "sh" = { };
          "chat" = { };
        };

        binds = {
          "Mod+Shift+Slash".action.show-hotkey-overlay = { };
          "Mod+Return".action.spawn = [ "ghostty" ];
          "Mod+D".action.spawn = [ "fuzzel" ];
          "Mod+Q".action.close-window = { };
          "Mod+Shift+E".action.quit = { };
          "Mod+W".action.toggle-column-tabbed-display = { };
          "Mod+T".action.toggle-window-floating = { };

          "Alt+Space".action.spawn = [ "${pkgs.fuzzel}/bin/fuzzel" ];
          "Alt+Tab".action.focus-window-down-or-column-right = { };

          "Print".action.spawn = [
            "sh"
            "-c"
            "filename=$(date +%Y-%m-%d-%H-%M-%S).png && ${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp)\" ~/Pictures/screenshot-$filename && ${pkgs.satty}/bin/satty --filename ~/Pictures/screenshot-$filename"
          ];
          "Shift+Print".action.spawn = [
            "sh"
            "-c"
            "filename=$(date +%Y-%m-%d-%H-%M-%S).png && ${pkgs.grim}/bin/grim ~/Pictures/screenshot-$filename && ${pkgs.satty}/bin/satty --filename ~/Pictures/screenshot-$filename"
          ];
          "Mod+V".action.spawn = [
            "clipman"
            "pick"
            "--tool=CUSTOM"
            "--tool-args=\"fuzzel -d\""
          ];
          "Mod+N".action.spawn = [
            "${pkgs.swaynotificationcenter}/bin/swaync-client"
            "-t"
            "-sw"
          ];
          "Mod+L".action.spawn = [
            "${pkgs.swaylock}/bin/swaylock"
            "-f"
          ];
          "Mod+Escape".action.spawn = [ "${pkgs.wlogout}/bin/wlogout" ];
          "Mod+Slash".action.spawn = [
            "sh"
            "-c"
            ''${pkgs.libnotify}/bin/notify-send -t 10000 "Niri Keybindings" "Launchers:\nMod+Return - Terminal\nMod+D / Alt+Space - Fuzzel\n\nWindow:\nMod+Q - Close\nMod+T - Float\nMod+F - Maximize\nMod+Shift+F - Fullscreen\n\nFocus:\nMod+Arrows - Navigate\nMod+1-9 - Workspace\nAlt+Tab - Cycle\n\nMove:\nMod+Shift+Arrows - Move window\nMod+Shift+1-9 - To workspace\n\nResize:\nMod+R - Cycle presets\nMod+[-/=] - Width\nMod+Shift+[-/=] - Height\n\nUtilities:\nMod+L - Lock\nMod+N - Notifications\nMod+V - Clipboard\nMod+Escape - Power menu\nPrint - Screenshot area\nShift+Print - Full screenshot"''
          ];

          "XF86AudioMute".action.spawn = [
            "${pkgs.pamixer}/bin/pamixer"
            "-t"
          ];
          "XF86AudioLowerVolume".action.spawn = [
            "${pkgs.pamixer}/bin/pamixer"
            "-d"
            "5"
          ];
          "XF86AudioRaiseVolume".action.spawn = [
            "${pkgs.pamixer}/bin/pamixer"
            "-i"
            "5"
          ];
          "XF86AudioMicMute".action.spawn = [
            "${pkgs.pamixer}/bin/pamixer"
            "-t"
            "--source"
            "alsa_input.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__hw_sofhdadsp_6__source"
          ];

          "XF86MonBrightnessDown".action.spawn = [
            "light"
            "-U"
            "5"
          ];
          "XF86MonBrightnessUp".action.spawn = [
            "light"
            "-A"
            "5"
          ];

          "XF86Display".action.spawn = [ "wdisplays" ];
          "XF86WLAN".action.spawn = [ "nm-connection-editor" ];
          "XF86Tools".action.spawn = [ "foot" ];
          "XF86Bluetooth".action.spawn = [ "blueman-manager" ];
          "XF86Favorites".action.spawn = [ "${pkgs.google-chrome}/bin/google-chrome" ];
          "XF86Sleep".action.spawn = [
            "systemctl"
            "suspend"
          ];

          "Mod+1".action.focus-workspace = 1;
          "Mod+2".action.focus-workspace = 2;
          "Mod+3".action.focus-workspace = 3;
          "Mod+4".action.focus-workspace = 4;
          "Mod+5".action.focus-workspace = 5;
          "Mod+6".action.focus-workspace = 6;
          "Mod+7".action.focus-workspace = 7;
          "Mod+8".action.focus-workspace = 8;
          "Mod+9".action.focus-workspace = 9;
          "Mod+0".action.focus-workspace = 10;

          "Mod+Shift+1".action.move-column-to-workspace = 1;
          "Mod+Shift+2".action.move-column-to-workspace = 2;
          "Mod+Shift+3".action.move-column-to-workspace = 3;
          "Mod+Shift+4".action.move-column-to-workspace = 4;
          "Mod+Shift+5".action.move-column-to-workspace = 5;
          "Mod+Shift+6".action.move-column-to-workspace = 6;
          "Mod+Shift+7".action.move-column-to-workspace = 7;
          "Mod+Shift+8".action.move-column-to-workspace = 8;
          "Mod+Shift+9".action.move-column-to-workspace = 9;
          "Mod+Shift+0".action.move-column-to-workspace = 10;

          "Mod+Left".action.focus-column-left = { };
          "Mod+Right".action.focus-column-right = { };
          "Mod+Up".action.focus-window-up = { };
          "Mod+Down".action.focus-window-down = { };

          "Mod+Shift+Left".action.move-column-left = { };
          "Mod+Shift+Right".action.move-column-right = { };
          "Mod+Shift+Up".action.move-window-up = { };
          "Mod+Shift+Down".action.move-window-down = { };

          "Mod+Home".action.focus-column-first = { };
          "Mod+End".action.focus-column-last = { };

          "Mod+Comma".action.consume-window-into-column = { };
          "Mod+Period".action.expel-window-from-column = { };

          "Mod+BracketLeft".action.consume-or-expel-window-left = { };
          "Mod+BracketRight".action.consume-or-expel-window-right = { };

          "Mod+R".action.switch-preset-column-width = { };
          "Mod+Shift+R".action.reset-window-height = { };
          "Mod+F".action.maximize-column = { };
          "Mod+Shift+F".action.fullscreen-window = { };

          "Mod+Minus".action.set-column-width = "-10%";
          "Mod+Equal".action.set-column-width = "+10%";

          "Mod+Shift+Minus".action.set-window-height = "-10%";
          "Mod+Shift+Equal".action.set-window-height = "+10%";
        };

        window-rules = [
          {
            geometry-corner-radius = {
              top-left = 20.0;
              top-right = 20.0;
              bottom-left = 20.0;
              bottom-right = 20.0;
            };
            clip-to-geometry = true;
          }
          {
            matches = [ { title = "obs-shared"; } ];
            default-column-width = {
              fixed = 1363;
            };
            open-floating = true;
          }
          {
            matches = [ { app-id = "google-chrome"; } ];
            draw-border-with-background = false;
          }
          {
            matches = [ { app-id = "^firefox$"; } ];
            open-on-workspace = "browser";
          }
          {
            matches = [ { app-id = "^discord$"; } ];
            open-on-workspace = "discord";
          }
          {
            matches = [ { app-id = "^org.telegram.desktop$"; } ];
            open-on-workspace = "chat";
          }
          {
            matches = [ { app-id = "^Slack$"; } ];
            open-on-workspace = "chat";
          }
        ];
      };
    };

    home.packages = with pkgs; [
      niri
      xwayland-satellite
      waybar
      waybar-mpris
      pwvucontrol
      alacritty
      starship
      google-chrome
      playerctl
      tree
      pavucontrol
      slurp
      grim
      satty
      swww
      wshowkeys
      libnotify
      xdg-utils
      glib
      gsettings-desktop-schemas
      wdisplays
      swaynotificationcenter
      dmenu-bluetooth
      bemoji
      bitwarden-menu
      networkmanagerapplet
      imagemagickBig
      xfce.thunar
      xfce.thunar-volman
      showmethekey
      gimp
      squeekboard
      wl-mirror
      xdotool
      udiskie
      orca-slicer
      hyprpicker
      wl-clipboard
      droidcam
      clipman
      wf-recorder
      wofi
      wlsunset
      sway-audio-idle-inhibit
      kanshi
      wlogout
      swayosd
      crystal-dock
      (pkgs.wrapOBS {
        plugins = with pkgs.obs-studio-plugins; [
          wlrobs
          obs-pipewire-audio-capture
        ];
      })
    ];

    services.blueman-applet.enable = true;
    services.network-manager-applet.enable = true;
  };
}
