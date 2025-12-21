{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

let
  cfg = config.shift.niri;

  niri-config = pkgs.writeText "niri-config.kdl" ''
    input {
        keyboard {
            repeat-delay 600
            repeat-rate 25
            xkb {
                layout "us,de"
                options "eurosign:e,ctrl:nocaps,grp:alt_shift_toggle"
            }
        }
        touchpad {
            tap
            natural-scroll
            click-method "clickfinger"
            scroll-method "two-finger"
            dwt
        }
    }

    layout {
        gaps 5
    }

    prefer-no-csd

    spawn-at-startup "waybar" "nm-applet" "swaync" "udiskie" "--tray" "swww" "init"

    binds {
        "Mod+Return" { spawn "alacritty"; }
        "Mod+Space" { spawn "fuzzel"; }
        "Mod+Q" { close-window; }
        "Mod+Shift+E" { spawn "systemctl" "poweroff"; }
        "Mod+Shift+R" { spawn "systemctl" "reboot"; }
        "Mod+L" { spawn "swaylock"; }

        // Navigation
        "Mod+Left" { focus-column-left; }
        "Mod+Down" { focus-window-down; }
        "Mod+Up" { focus-window-up; }
        "Mod+Right" { focus-column-right; }
        "Mod+Shift+Left" { move-column-left; }
        "Mod+Shift+Down" { move-window-down; }
        "Mod+Shift+Up" { move-window-up; }
        "Mod+Shift+Right" { move-column-right; }

        // Workspaces
        "Mod+1" { focus-workspace 1; }
        "Mod+2" { focus-workspace 2; }
        "Mod+3" { focus-workspace 3; }
        "Mod+4" { focus-workspace 4; }
        "Mod+5" { focus-workspace 5; }
        "Mod+6" { focus-workspace 6; }
        "Mod+7" { focus-workspace 7; }
        "Mod+8" { focus-workspace 8; }
        "Mod+9" { focus-workspace 9; }
        "Mod+0" { focus-workspace 10; }
        "Mod+Shift+1" { move-column-to-workspace 1; }
        "Mod+Shift+2" { move-column-to-workspace 2; }
        "Mod+Shift+3" { move-column-to-workspace 3; }
        "Mod+Shift+4" { move-column-to-workspace 4; }
        "Mod+Shift+5" { move-column-to-workspace 5; }
        "Mod+Shift+6" { move-column-to-workspace 6; }
        "Mod+Shift+7" { move-column-to-workspace 7; }
        "Mod+Shift+8" { move-column-to-workspace 8; }
        "Mod+Shift+9" { move-column-to-workspace 9; }
        "Mod+Shift+0" { move-column-to-workspace 10; }

        // Window management
        "Mod+F" { maximize-column; }
        "Mod+Shift+F" { fullscreen-window; }
        "Mod+C" { center-column; }
        "Mod+Comma" { consume-window-into-column; }
        "Mod+Period" { expel-window-from-column; }

        // Audio controls
        "XF86AudioMute" { spawn "pamixer" "-t"; }
        "XF86AudioLowerVolume" { spawn "pamixer" "-d" "5"; }
        "XF86AudioRaiseVolume" { spawn "pamixer" "-i" "5"; }

        // Brightness controls
        "XF86MonBrightnessDown" { spawn "light" "-U" "5"; }
        "XF86MonBrightnessUp" { spawn "light" "-A" "5"; }

        // Tools
        "XF86Tools" { spawn "alacritty"; }
        "XF86Bluetooth" { spawn "blueman-manager"; }
        "XF86Favorites" { spawn "google-chrome"; }
        "XF86Sleep" { spawn "systemctl" "suspend"; }

        // Screenshots
        "Print" { screenshot; }
        "Ctrl+Print" { screenshot-screen; }
        "Alt+Print" { screenshot-window; }
    }
  '';

in
{
  options.shift.niri = {
    enable = mkEnableOption "niri window manager";
  };

  config = mkIf cfg.enable {
    # Add niri to system packages if needed
    home.packages = with pkgs; [
      fuzzel
      alacritty
      starship
      google-chrome
      playerctl
      tree
      pavucontrol
      slurp
      grim
      swww
      wshowkeys
      way-displays
      wdisplays
      swaynotificationcenter
      dmenu-bluetooth
      bemoji
      bitwarden-menu
      waybar-mpris
      waybar
      networkmanagerapplet
      imagemagickBig
      xfce.thunar
      xfce.thunar-volman
      showmethekey
      gimp
      element-desktop
      squeekboard
      wl-mirror
      xdotool
      udiskie
      hyprpicker
      wl-clipboard
      droidcam
      light
      pamixer
      swaylock
      (pkgs.wrapOBS {
        plugins = with pkgs.obs-studio-plugins; [
          wlrobs
          obs-pipewire-audio-capture
        ];
      })
    ];

    services.blueman-applet.enable = true;
    services.network-manager-applet.enable = true;
    services.swaync.enable = true;
    services.easyeffects.enable = true;

    # Configure XDG config for niri
    xdg.configFile."niri/config.kdl".source = niri-config;

    # Enable wayland session
    # Note: You'll need to configure your display manager to use niri
    # or manually start it with `exec niri` in your session startup
  };
}