{ pkgs, ... }:
{

  programs.foot = {
    enable = true;
    server.enable = true;
    settings = {
      main = {
        shell = "${pkgs.tmux}/bin/tmux";
        pad = "12x12";
        selection-target = "both";
      };
    };
  };
}
