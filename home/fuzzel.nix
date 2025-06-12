{
  config,
  lib,
  pkgs,
  ...
}:
#let inherit (config.colorScheme) colors;
#in
{
  # TODO: migrate fuzzel.nix from hm module to home.file
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        # font = "JetBrainsMono Nerd Font:size=16";
        # terminal = "${config.wayland.windowManager.sway.config.terminal}";
        # icon-theme = "${config.gtk.iconTheme.name}";
      };
      dmenu = {
        mode = "text";
        exit-immediately-if-empty = "yes";
      };
      #      colors = {
      #        background = colors.base00 + "ff";
      #        text = colors.base07 + "ff";
      #        match = colors.base05 + "ff";
      #        selection = colors.base03 + "ff";
      #        selection-text = colors.base07 + "ff";
      #        selection-match = colors.base0D + "ff";
      #        border = colors.base02 + "ff";
      #      };
      border = {
        width = 3;
        radius = 7;
      };
    };
  };
}
