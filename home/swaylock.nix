{ config, pkgs, ... }:
let
  # exec swayidle -w \
  #    timeout 300 'systemctl suspend"' \
  #    resume 'swaymsg "output * dpms on"' \
  #    before-sleep 'swaylock -C ~/.config/swaylock/config' \
  #    lock 'swaylock -C ~/.config/swaylock/config'
  commonTimeout = 360;
  swaylockCommand = "${pkgs.swaylock}/bin/swaylock -f -c 000000";
  swaymsgCommand = "${pkgs.sway}/bin/swaymsg 'output * dpms off'";
  resumeCommand = "${pkgs.sway}/bin/swaymsg 'output * dpms on'";
in
{
  programs.swaylock = {
    enable = true;
  };
  services.swayidle = {
    enable = true;
    timeouts = [
      {
        timeout = commonTimeout;
        command = swaylockCommand;
      }
      {
        timeout = 2 * commonTimeout; # Use the commonTimeout variable here
        command = swaymsgCommand;
        resumeCommand = resumeCommand;
      }
    ];
    events = [
      {
        event = "before-sleep";
        command = "${pkgs.swaylock}/bin/swaylock -fF";
      }
    ];
  };
}
