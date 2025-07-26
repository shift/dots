{
  config,
  lib,
  pkgs,
  ...
}:
{
  # NIx configuration and optimization
  nix = {
    optimise = {
      automatic = true;
      dates = [ "03:45" ];
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

    settings = {
      max-jobs = lib.mkDefault "auto";
      system-features = [
        "benchmark"
        "big-parallel"
        "kvm"
        "nixos-test"
      ];
    };
  };

  # Nixpkgs configuration
  nixpkgs.config.allowUnfree = lib.mkDefault false;
  nixpkgs.config.permittedInsecurePackages = [
    # Add insecure packages as needed
  ];

  # System packages that are commonly needed
  environment.systemPackages = with pkgs; [
    neovim
    git
    gotop
    htop
    lm_sensors
    iw
    ethtool
    usbutils
    pciutils
    wol
    nmap
    iperf3
    plymouth
    android-tools
    android-udev-rules
    greetd.regreet
    disko
  ];

  # Documentation
  documentation.nixos.enable = true;
  documentation.info.enable = true;
  documentation.doc.enable = true;
}
