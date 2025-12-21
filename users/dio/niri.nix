{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

{
  config = mkIf config.programs.niri.enable {
    # Enable relevant services for niri/wayland
    services.network-manager-applet.enable = true;
    
    # Additional niri-specific configuration can go here
    # The dots-framework handles the main configuration
  };
}