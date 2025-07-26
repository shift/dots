{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Laptop-specific hardware configuration
  zramSwap.enable = true;

  services.tlp.enable = true;
  services.power-profiles-daemon.enable = lib.mkForce false;
  services.fprintd.enable = true;

  powerManagement = {
    enable = true;
    cpuFreqGovernor = "schedutil";
    powertop.enable = true;
  };

  hardware = {
    sane.enable = true;
    sane.extraBackends = [
      pkgs.hplipWithPlugin
      pkgs.sane-airscan
    ];
    enableAllFirmware = true;
    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          ControllerMode = "dual";
          FastConnectable = "true";
          Experimental = "true";
        };
        Policy = {
          AutoEnable = "true";
        };
      };
    };
  };

  # Intel graphics hardware acceleration
  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-compute-runtime
      intel-media-driver
      intel-media-sdk
      vaapiVdpau
      libvdpau-va-gl
      vpl-gpu-rt
    ];
  };
}
