{ config, pkgs, lib, ... }:
let
  dimTimeout = 300;
  lockTimeout = 360;
  screenOffTimeout = 720;
  
  swaylockCommand = "${pkgs.swaylock}/bin/swaylock -f -c 000000";
  dimCommand = "${pkgs.brightnessctl}/bin/brightnessctl -s set 10%";
  dimResumeCommand = "${pkgs.brightnessctl}/bin/brightnessctl -r";
  
  wayland-compositor = config.home.sessionVariables.XDG_CURRENT_DESKTOP or null;
  
  dpmsOffCommand = 
    if wayland-compositor == "sway" then "${pkgs.sway}/bin/swaymsg 'output * dpms off'"
    else if wayland-compositor == "niri" then "${pkgs.niri}/bin/niri msg action power-off-monitors"
    else if wayland-compositor == "Hyprland" then "${pkgs.hyprland}/bin/hyprctl dispatch dpms off"
    else null;
    
  dpmsOnCommand = 
    if wayland-compositor == "sway" then "${pkgs.sway}/bin/swaymsg 'output * dpms on'"
    else if wayland-compositor == "niri" then "${pkgs.niri}/bin/niri msg action power-on-monitors"
    else if wayland-compositor == "Hyprland" then "${pkgs.hyprland}/bin/hyprctl dispatch dpms on"
    else null;
in
{
  programs.swaylock = {
    enable = true;
    settings = {
      font-size = 24;
      indicator-idle-visible = false;
      indicator-radius = 100;
      show-failed-attempts = true;
    };
  };
  
  services.swayidle = lib.mkIf (wayland-compositor != null) {
    enable = true;
    systemdTarget = 
      if wayland-compositor == "sway" then "sway-session.target"
      else if wayland-compositor == "niri" then "niri.service"
      else if wayland-compositor == "Hyprland" then "hyprland-session.target"
      else "graphical-session.target";
    timeouts = [
      {
        timeout = dimTimeout;
        command = dimCommand;
        resumeCommand = dimResumeCommand;
      }
      {
        timeout = lockTimeout;
        command = swaylockCommand;
      }
    ] ++ lib.optionals (dpmsOffCommand != null) [
      {
        timeout = screenOffTimeout;
        command = dpmsOffCommand;
        resumeCommand = dpmsOnCommand;
      }
    ];
    events = [
      {
        event = "before-sleep";
        command = "${pkgs.swaylock}/bin/swaylock -fF";
      }
      {
        event = "lock";
        command = swaylockCommand;
      }
    ];
  };
}
