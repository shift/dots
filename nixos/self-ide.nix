{ flake, ... }:
{
  security.sudo.extraRules = [
    {
      users = [ flake.config.people.myself ];
      commands = [
        {
          command = "/run/current-system/sw/bin/nixos-rebuild";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
