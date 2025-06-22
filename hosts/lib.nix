# Host configuration utilities
{ lib, pkgs ? null, ... }:

{
  # Read and parse a host's factor.json file
  readHostFactor = hostPath:
    let
      factorFile = hostPath + "/factor.json";
      factorExists = builtins.pathExists factorFile;
    in
    if factorExists
    then builtins.fromJSON (builtins.readFile factorFile)
    else { };

  # Generate hardware configuration from factor data
  mkHardwareConfig = factor: {
    # CPU configuration
    powerManagement = lib.mkIf (factor.hardware.cpu or null != null) {
      enable = true;
      cpuFreqGovernor = factor.hardware.cpu.governor or "schedutil";
      powertop.enable = true;
    };

    # Graphics configuration (when pkgs is available)
    hardware.graphics = lib.mkIf (factor.features.graphics.enable or false) (
      {
        enable = true;
      } // lib.optionalAttrs (pkgs != null && factor.hardware.gpu.vendor or null == "intel") {
        extraPackages = with pkgs; [
          intel-compute-runtime
          intel-media-driver
          vaapiVdpau
          libvdpau-va-gl
        ];
      }
    );

    # Intel graphics overrides (when pkgs is available)
    nixpkgs.config.packageOverrides = lib.mkIf (pkgs != null && factor.hardware.gpu.vendor or null == "intel") (pkgs: {
      vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
    });

    # Memory configuration
    zramSwap.enable = factor.hardware.memory.zramSwap or false;

    # Hardware features
    hardware.enableAllFirmware = true;

    # Nix configuration
    nix = lib.mkIf (factor.nix or null != null) {
      optimise = lib.mkIf (factor.nix.optimise or null != null) {
        automatic = factor.nix.optimise.automatic or true;
        dates = factor.nix.optimise.dates or [ "03:45" ];
      };
      gc = lib.mkIf (factor.nix.gc or null != null) {
        automatic = factor.nix.gc.automatic or true;
        dates = factor.nix.gc.dates or "weekly";
        options = factor.nix.gc.options or "--delete-older-than 30d";
      };
      settings = {
        max-jobs = lib.mkForce (factor.nix.maxJobs or 1);
        system-features = factor.hardware.cpu.features or [
          "benchmark"
          "big-parallel" 
          "kvm"
          "nixos-test"
        ];
      };
    };
  };

  # Generate services configuration from factor data
  mkServicesConfig = factor: {
    # Bluetooth
    hardware.bluetooth = lib.mkIf (factor.features.bluetooth.enable or false) {
      enable = true;
      powerOnBoot = factor.features.bluetooth.powerOnBoot or true;
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

    # WiFi/Networking
    networking.networkmanager = lib.mkIf (factor.features.wifi.enable or false) {
      enable = factor.features.wifi.networkmanager or true;
    };
    networking.wireless.dbusControlled = lib.mkIf (factor.features.wifi.enable or false) (
      factor.features.wifi.dbusControlled or true
    );

    # TLP power management
    services.tlp.enable = factor.features.tlp.enable or false;
    services.power-profiles-daemon.enable = lib.mkForce (!factor.features.tlp.enable or true);

    # Fingerprint reader
    services.fprintd.enable = factor.features.fingerprint.enable or false;

    # Scanner support (when pkgs is available)
    hardware.sane = lib.mkIf (factor.features.scanner.enable or false) (
      {
        enable = true;
      } // lib.optionalAttrs (pkgs != null) {
        extraBackends = with pkgs; [
          hplipWithPlugin
          sane-airscan
        ];
      }
    );
  };

  # Generate complete configuration from factor
  mkHostConfig = hostPath:
    let
      factor = readHostFactor hostPath;
      hardwareConfig = mkHardwareConfig factor;
      servicesConfig = mkServicesConfig factor;
    in
    lib.recursiveUpdate hardwareConfig servicesConfig // {
      # State version from factor
      system.stateVersion = factor.stateVersion or "25.05";
      nixpkgs.hostPlatform = lib.mkDefault (factor.hostPlatform or "x86_64-linux");
    };
}