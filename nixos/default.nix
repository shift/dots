{
  self,
  config,
  inputs,
  ...
}:

{
  # Configuration common to all Linux systems
  flake = {
    nixosModules = {
      # NixOS modules that are known to work on nix-darwin.
      common.imports = [
        ./nix.nix
        ./caches
        ./stylix.nix
      ];

      my-home = {
        users.users.${config.people.myself}.isNormalUser = true;
        home-manager.users.${config.people.myself} = {
          imports = [
            self.homeModules.common-linux
            inputs.nixvim.homeManagerModules.nixvim
          ];
        };
      };

      default.imports = [
        #        self.nixosModules.home-manager
        self.nixosModules.my-home
        self.nixosModules.common
        ./self-ide.nix
        #        ./ssh-authorize.nix
        ./current-location.nix
        ./fontconfig.nix
      ];
    };
  };
}
