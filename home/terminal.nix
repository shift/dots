{ pkgs, lib, ... }:

# Platform-independent terminal setup
{
  home.packages = with pkgs; [
    # Useful for Nix development
    nil
    nixpkgs-fmt
    nixpkgs-review
    # Publishing
    asciinema

    # Dev
    gh
  ];

  home.shellAliases = { };

  programs = {
    bat.enable = true;
    autojump.enable = false;
    zoxide.enable = true;
    fzf.enable = true;
    jq.enable = true;
    nix-index.enable = true;
    htop.enable = true;
    yazi = {
      enable = true;
      enableZshIntegration = true;
    };
    zsh.enable = true;
  };
}
