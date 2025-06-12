{ pkgs, ... }:

{
  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    bitwarden
    bitwarden-cli
    devbox
  ];
  programs.zsh.enable = true;
  # This must be envExtra (rather than initExtra), because doom-emacs requires it
  # https://github.com/doomemacs/doomemacs/issues/687#issuecomment-409889275
  #
  # But also see: 'doom env', which is what works.
  programs.zsh.envExtra = ''
    export PATH=/run/wrappers/bin:/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin/:$PATH
  '';

  programs.nix-index.enableZshIntegration = true;
}
