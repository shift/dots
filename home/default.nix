{ self, ... }:
{
  flake = {
    homeModules = {
      common = {
        imports = [
          ./tmux.nix
          ./nixvim.nix
          ./starship.nix
          ./terminal.nix
          ./git.nix
          ./direnv.nix
          ./just.nix
          ./sway.nix
          ./waybar/default.nix
          ./swaylock.nix
          ./options.nix
        ];
      };
      common-linux = {
        imports = [
          self.homeModules.common
          ./zsh.nix
        ];
      };
    };
  };
}
