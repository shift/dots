{
  lib,
  pkgs,
  ...
}:
{
  # Audio configuration with PipeWire
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };

  # Printing services
  services.printing.enable = true;

  # Scanner support (included in laptop.nix as well, but can be used independently)
  hardware.sane.enable = lib.mkDefault true;
  hardware.sane.extraBackends = lib.mkDefault [
    pkgs.hplipWithPlugin
    pkgs.sane-airscan
  ];
}
