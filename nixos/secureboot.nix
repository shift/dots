{
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  boot = {
    initrd.verbose = false;
    initrd.systemd.enable = true;
    loader = {
      systemd-boot = {
        enable = lib.mkDefault false;
        editor = lib.mkDefault false;
      };
      efi.canTouchEfiVariables = true;
      timeout = lib.mkDefault 0;
    };
    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };
  };
  environment.systemPackages = [ pkgs.sbctl ];
  environment.persistence = {
    "/persist".directories = [ "/var/lib/sbctl" ];
  };
}
