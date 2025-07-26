{
  lib,
  pkgs,
  ...
}:
{
  # Boot configuration for ThinkPad with encryption and Plymouth
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;

    kernelParams = [
      "quiet"
      "mem_sleep_default=deep"
      "splash"
      "loglevel=3"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "rd.luks.options=tpm2-measure-pcr=yes"
      "udev.log_priority=3"
      "resume_offset=533760"
      "bgrt_disable=1"
    ];

    resumeDevice = "/dev/mapper/crypted";

    initrd.availableKernelModules = [
      "xhci_pci"
      "ehci_pci"
      "ahci"
      "uas"
      "sd_mod"
      "rtsx_pci_sdmmc"
    ];

    kernelModules = [ "kvm-intel" ];
    consoleLogLevel = 0;

    supportedFilesystems = [
      "btrfs"
      "vfat"
    ];

    tmp.cleanOnBoot = true;

    # Plymouth boot splash
    plymouth = {
      enable = true;
      theme = lib.mkDefault pkgs.plymouth-matrix-theme;
    };

    extraModprobeConfig = ''
      options v4l2loopback devices=1 exclusive_caps=1 video_nr=5 card_label="OBS Cam"
    '';
  };

  # Console configuration
  console = {
    keyMap = lib.mkForce "us";
    useXkbConfig = true; # use xkb.options in tty.
  };
}
