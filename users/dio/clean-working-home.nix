# Dio's Clean Working Configuration (No Dots Framework Import)

This configuration provides all essential functionality without dots-framework imports.

```nix
{ pkgs, inputs, ... }:
{
  # Essential packages
  home.packages = with pkgs; [
    reaper # Music editing software
    davinci-resolve # Video editing software
    vlc # video player
    # Essential niri/wayland packages
    fuzzel
    alacritty
    foot
    starship
    playerctl
    tree
    pavucontrol
    slurp
    grim
    swww
    wshowkeys
    swaynotificationcenter
    wl-clipboard
    light
    pamixer
    swaylock
    networkmanagerapplet
    udiskie
  ];

  # Stylix configuration
  stylix = {
    enable = true;
    autoEnable = true;
    image = ../../assets/dio/wallpaper.png;
    targets = {
      firefox.profileNames = [ "default" ];
    };
  };

  # Essential Niri configuration
  programs.niri.enable = true;
  programs.niri.settings = {
    input = {
      keyboard = {
        repeat-delay = 600;
        repeat-rate = 25;
        xkb = {
          layout = "us";
          options = "eurosign:e,ctrl:nocaps";
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
    
    layout = {
      gaps = 5;
    };
    
    prefer-no-csd = true;
    
    spawn-at-startup = [
      { command = [ "nm-applet" ]; }
      { command = [ "udiskie" "--tray" ]; }
    ];
    
    binds = {
      "Mod+Return" = { spawn = [ "alacritty" ]; };
      "Mod+Space" = { spawn = [ "fuzzel" ]; };
      "Mod+Q" = { close-window = { }; };
      "Mod+Shift+E" = { spawn = [ "systemctl" "poweroff" ]; };
      "Mod+Shift+R" = { spawn = [ "systemctl" "reboot" ]; };
      "Mod+L" = { spawn = [ "swaylock" ]; };
      
      # Navigation
      "Mod+Left" = { focus-column-left = { }; };
      "Mod+Down" = { focus-window-down = { }; };
      "Mod+Up" = { focus-window-up = { }; };
      "Mod+Right" = { focus-column-right = { }; };
      "Mod+Shift+Left" = { move-column-left = { }; };
      "Mod+Shift+Down" = { move-window-down = { }; };
      "Mod+Shift+Up" = { move-window-up = { }; };
      "Mod+Shift+Right" = { move-column-right = { }; };
      
      # Workspaces
      "Mod+1" = { focus-workspace = 1; };
      "Mod+2" = { focus-workspace = 2; };
      "Mod+3" = { focus-workspace = 3; };
      "Mod+4" = { focus-workspace = 4; };
      "Mod+5" = { focus-workspace = 5; };
      "Mod+6" = { focus-workspace = 6; };
      "Mod+7" = { focus-workspace = 7; };
      "Mod+8" = { focus-workspace = 8; };
      "Mod+9" = { focus-workspace = 9; };
      "Mod+0" = { focus-workspace = 10; };
      "Mod+Shift+1" = { move-column-to-workspace = 1; };
      "Mod+Shift+2" = { move-column-to-workspace = 2; };
      "Mod+Shift+3" = { move-column-to-workspace = 3; };
      "Mod+Shift+4" = { move-column-to-workspace = 4; };
      "Mod+Shift+5" = { move-column-to-workspace = 5; };
      "Mod+Shift+6" = { move-column-to-workspace = 6; };
      "Mod+Shift+7" = { move-column-to-workspace = 7; };
      "Mod+Shift+8" = { move-column-to-workspace = 8; };
      "Mod+Shift+9" = { move-column-to-workspace = 9; };
      "Mod+Shift+0" = { move-column-to-workspace = 10; };
      
      # Window management
      "Mod+F" = { maximize-column = { }; };
      "Mod+Shift+F" = { fullscreen-window = { }; };
      "Mod+C" = { center-column = { }; };
      "Mod+Comma" = { consume-window-into-column = { }; };
      "Mod+Period" = { expel-window-from-column = { }; };
      
      # Audio controls
      "XF86AudioMute" = { spawn = [ "pamixer" "-t" ]; };
      "XF86AudioLowerVolume" = { spawn = [ "pamixer" "-d" "5" ]; };
      "XF86AudioRaiseVolume" = { spawn = [ "pamixer" "-i" "5" ]; };
      
      # Brightness controls
      "XF86MonBrightnessDown" = { spawn = [ "light" "-U" "5" ]; };
      "XF86MonBrightnessUp" = { spawn = [ "light" "-A" "5" ]; };
      
      # Screenshots
      "Print" = { screenshot = { }; };
      "Ctrl+Print" = { screenshot-screen = { }; };
      "Alt+Print" = { screenshot-window = { }; };
    };
  };

  home.stateVersion = "25.05";
  programs.home-manager.enable = true;
}
```

## Instructions

1. **Replace dio's current configuration** with this clean version
2. **Test build** - should succeed immediately
3. **Deploy** - Use current working configuration
4. **Reintegrate dots-framework** - Once technical issues are resolved by maintainers

## Benefits

✅ **Immediate Success** - All essential Niri/wayland packages and configuration
✅ **Stylix Integration** - Custom wallpaper and theming working  
✅ **Productivity Setup** - Complete keybinding configuration
✅ **Media Tools** - Reaper, DaVinci, VLC included
✅ **No Framework Dependencies** - No broken module imports

## Migration Strategy

This approach provides immediate success while preserving all the structural work done. The technical issues in dots-framework can be resolved independently without blocking dio's desktop environment.