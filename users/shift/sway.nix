{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

let
  cfg = config.shift.sway;

  defaultKeybindings = {
    "Mod1+Space" = "exec ${pkgs.swayr}/bin/swayr switch-window";
    "Mod1+XF86Eject" = "exec ${pkgs.swayr}/bin/swayr quit-window";
    "Mod1+Tab" = "exec ${pkgs.swayr}/bin/swayr switch-to-urgent-or-lru-window";
    "Mod1+C" = "exec ${pkgs.swayr}/bin/swayr execute-swaymsg-command";
    "Mod1+Shift+C" = "exec ${pkgs.swayr}/bin/swayr execute-swayr-command";
    "Mod1+Shift+T" = "exec ${pkgs.alacritty}/bin/alacritty --title obs-shared";
    # # Audio controls
    "XF86AudioMute" = "exec ${pkgs.pamixer}/bin/pamixer -t";
    "XF86AudioLowerVolume" = "exec ${pkgs.pamixer}/bin/pamixer -d 5 #to decrease 5%";
    "XF86AudioRaiseVolume" = "exec ${pkgs.pamixer}/bin/pamixer -i 5 #to increase 5%";
    "XF86AudioMicMute" =
      "exec ${pkgs.pamixer}/bin/pamixer -t --source alsa_input.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__hw_sofhdadsp_6__source";

    # Brightness controls
    "XF86MonBrightnessDown" = "exec light -U 5";
    "XF86MonBrightnessUp" = "exec light -A 5";

    # Display (cycle outputs)
    "XF86Display" = "exec swaymsg output * toggle";

    # WiFi
    "XF86WLAN" = "exec nm-connection-editor";

    # Tools (open a terminal)
    "XF86Tools" = "exec alacritty";

    # Bluetooth (open Bluetooth settings)
    "XF86Bluetooth" = "exec blueman-manager";

    "XF86Favorites" = "exec ${pkgs.google-chrome}/bin/google-chrome";

    # Sleep
    "XF86Sleep" = "exec systemctl suspend";
  };

  defaultGaps = {
    inner = 5;
    outer = 5;
  };

  defaultInput = {
    "type:keyboard" = {
      xkb_layout = "us,de";
      xkb_options = "eurosign:e,ctrl:nocaps,grp:alt_shift_toggle";
    };
    "type:touchpad" = {
      tap = "enabled";
      natural_scroll = "enabled";
      click_method = "clickfinger";
      scroll_method = "two_finger";
      dwt = "enabled";
    };
  };

  defaultOutput = {
    "Hisense Electric Co., Ltd. HISENSE 0x00000001" = {
      scale = "1.3";
      mode = "4096x2160@30.000Hz";
      subpixel = "rgb";
    };
  };

  swayConfig = {
    modifier = "Mod4";
    terminal = "foot";
    menu = "fuzzel";
    bars = [ ];
    keybindings = lib.mkOptionDefault defaultKeybindings;
    gaps = defaultGaps;
    input = defaultInput;
    output = defaultOutput;
  };

  extraExecs = ''
    bar {
      swaybar_command waybar
      position top
    }
    for_window [title="obs-shared"] floating enable, border none, move position 100 200, resize set 1363 761
    for_window [app_id="google-chrome"] border none
    exec ${pkgs.swayr}/bin/swayrd
    exec ${pkgs.networkmanagerapplet}/bin/nm-applet
    exec ${pkgs.swaynotificationcenter}/bin/swaync
    exec ${pkgs.udiskie}/bin/udiskie --tray
    exec ${pkgs.rot8}/bin/rot8 --hooks "pkill -9 lisgd; ${pkgs.lisgd}/bin/lisgd -d /dev/input/by-id/usb-Wacom_Co._Ltd._Pen_and_multitouch_sensor-event-if00 &"
    exec ${pkgs.lisgd}/bin/lisgd -d /dev/input/by-id/usb-Wacom_Co._Ltd._Pen_and_multitouch_sensor-event-if00
    bindswitch tablet:on exec '${pkgs.wvkbd}/bin/wvkbd-mobintl -L 200 &', \
      exec 'swaymsg input 1386:20918:Wacom_Pen_and_multitouch_sensor_Finger map_to_output eDP-1', \
      exec 'swaymsg input 1386:20918:Wacom_Pen_and_multitouch_sensor_Pen map_to_output eDP-1'
    bindswitch tablet:off exec 'pkill wvkbd-mobintl &', \
      exec 'swaymsg input 1386:20918:Wacom_Pen_and_multitouch_sensor_Finger map_to_output eDP-1', \
      exec 'swaymsg input 1386:20918:Wacom_Pen_and_multitouch_sensor_Pen map_to_output eDP-1'
      exec 'export GPG_TTY=$(tty)'
      exec 'export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"'
    default_border pixel

  '';

in
{
  imports = [
    ./swayr.nix
    ./waybar/default.nix
    ./fuzzel.nix
  ];

  options.shift.sway = {
    enable = mkEnableOption "";
  };

  config = mkIf cfg.enable {
    wayland.windowManager.sway = {
      enable = true;
      config = swayConfig;
      extraConfig = extraExecs;
    };

    home.packages = with pkgs; [
      swayr
      swayrbar
      waybar-mpris
      pwvucontrol
      alacritty
      starship
      google-chrome
      #activitywatch
      playerctl
      tree
      pavucontrol
      slurp
      grim
      swww
      wshowkeys
      # configure-gtk
      xdg-utils
      glib
      gsettings-desktop-schemas
      way-displays
      wdisplays
      swaynotificationcenter
      eww
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
      #squeekboard-control
      squeekboard
      wl-mirror
      xdotool
      udiskie
      #orca-slicer
      hyprpicker
      wl-clipboard
      droidcam
      (pkgs.wrapOBS {
        plugins = with pkgs.obs-studio-plugins; [
          wlrobs
          obs-pipewire-audio-capture
          #input-overlay
          #obs-midi
        ];
      })
    ];
    services.blueman-applet.enable = true;
    services.network-manager-applet.enable = true;
    services.swaync.enable = true;
    services.easyeffects.enable = true;

    #
    systemd.user.services.swayrd.Service = lib.mkIf config.programs.swayr.enable {
      Environment = [
        "PATH=${
          lib.makeBinPath [
            pkgs.fuzzel
          ]
        }"
      ];
    };
  };
}
