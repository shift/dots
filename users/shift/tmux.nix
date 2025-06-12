{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    aggressiveResize = true;
    baseIndex = 1;
    newSession = true;
    escapeTime = 0;
    secureSocket = false;
    clock24 = true;
    shortcut = "a";
    terminal = "tmux-direct";

    plugins = with pkgs; [
      tmuxPlugins.tmux-fzf
      tmuxPlugins.better-mouse-mode
      tmuxPlugins.weather
      tmuxPlugins.vim-tmux-focus-events
      tmuxPlugins.tmux-thumbs
    ];

    extraConfig = ''
      set -ga terminal-overrides ",*:RGB"
      set-environment -g COLORTERM "truecolor"
      set-environment -g EDITOR "nvim"

      # Mouse works as expected
      set-option -g mouse on
      bind c new-window -c "#{pane_current_path}"
    '';
  };
}
