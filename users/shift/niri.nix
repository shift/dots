{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;

let
  cfg = config.shift.niri;

  defaultKeybindings = {
    "Mod+Space" = "spawn ${pkgs.fuzzel}/bin/fuzzel";
    "Mod+Return" = "spawn ${pkgs.alacritty}/bin/alacritty";
    "Mod+Q" = "close-window";
    "Mod+Shift+Q" = "close-window";
    "Mod+D" = "spawn ${pkgs.fuzzel}/bin/fuzzel";
    "Mod+Shift+E" = "spawn ${pkgs.systemd}/bin/systemctl poweroff";
    "Mod+Shift+R" = "spawn ${pkgs.systemd}/bin/systemctl reboot";
    "Mod+L" = "spawn ${pkgs.swaylock}/bin/swaylock";

    # Navigation
    "Mod+Left" = "focus-column-left";
    "Mod+Down" = "focus-window-down";
    "Mod+Up" = "focus-window-up";
    "Mod+Right" = "focus-column-right";
    "Mod+Shift+Left" = "move-column-left";
    "Mod+Shift+Down" = "move-window-down";
    "Mod+Shift+Up" = "move-window-up";
    "Mod+Shift+Right" = "move-column-right";

    # Workspaces
    "Mod+1" = "workspace 1";
    "Mod+2" = "workspace 2";
    "Mod+3" = "workspace 3";
    "Mod+4" = "workspace 4";
    "Mod+5" = "workspace 5";
    "Mod+Shift+1" = "move-column-to-workspace 1";
    "Mod+Shift+2" = "move-column-to-workspace 2";
    "Mod+Shift+3" = "move-column-to-workspace 3";
    "Mod+Shift+4" = "move-column-to-workspace 4";
    "Mod+Shift+5" = "move-column-to-workspace 5";

    # Layout
    "Mod+A" = "set-layout "smart"";

    # Audio controls
    "XF86AudioMute" = "spawn ${pkgs.pamixer}/bin/pamixer -t";
    "XF86AudioLowerVolume" = "spawn ${pkgs.pamixer}/bin/pamixer -d 5";
    "XF86AudioRaiseVolume" = "spawn ${pkgs.pamixer}/bin/pamixer -i 5";
    "XF86AudioMicMute" = "spawn ${pkgs.pamixer}/bin/pamixer -t --source alsa_input.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__hw_sofhdadsp_6__source";

    # Brightness controls
    "XF86MonBrightnessDown" = "spawn ${pkgs.light}/bin/light -U 5";
    "XF86MonBrightnessUp" = "spawn ${pkgs.light}/bin/light -A 5";

    # Tools
    "XF86Tools" = "spawn ${pkgs.alacritty}/bin/alacritty";
    "XF86Bluetooth" = "spawn ${pkgs.blueman-manager}/bin/blueman-manager";
    "XF86Favorites" = "spawn ${pkgs.google-chrome}/bin/google-chrome";
    "XF86Sleep" = "spawn ${pkgs.systemd}/bin/systemctl suspend";
  };

in
{
  options.shift.niri = {
    enable = mkEnableOption "niri window manager";
  };

  config = mkIf cfg.enable {
    programs.niri = {
      enable = true;
      package = inputs.niri.packages.${pkgs.system}.niri;
      settings = {
        input = {
          keyboard = {
            repeat-delay = 600;
            repeat-rate = 25;
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
        };

        outputs = {
          "Hisense Electric Co., Ltd. HISENSE 0x00000001" = {
            scale = 1.3;
            mode = {
              width = 4096;
              height = 2160;
              refresh = 30.0;
            };
          };
        };

        layout = {
          gaps = 5;
          default-column-width = { proportion = 0.5; };
          center-focused-column = "never";
        };

        prefer-no-csd = true;

        spawns-at-startup = [
          { command = [ "${pkgs.waybar}/bin/waybar" ]; }
          { command = [ "${pkgs.swayr}/bin/swayrd" ]; }
          { command = [ "${pkgs.networkmanagerapplet}/bin/nm-applet" ]; }
          { command = [ "${pkgs.swaynotificationcenter}/bin/swaync" ]; }
          { command = [ "${pkgs.udiskie}/bin/udiskie" "--tray" ]; }
          { command = [ "${pkgs.swww}/bin/swww" "init" ]; }
        ];

        binds = with config.programs.niri.settings; mapAttrsToList (key: action: {
          key = key;
          action = action;
        }) defaultKeybindings;

        window-rules = [
          {
            matches = [
              { app-id = "^google-chrome$"; }
            ];
            default-column-width = { proportion = 0.75; };
          }
          {
            matches = [
              { title = "^obs-shared$"; }
            ];
            open-floating = true;
          }
        ];
      };
    };

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

    # Import related configuration
    imports = [
      ./waybar/default.nix
      ./fuzzel.nix
    ];
  };
}