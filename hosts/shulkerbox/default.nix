{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:
{
  imports = [
    ../../nixos/nix.nix
    ../../nixos/sshd.nix
    ../../nixos/current-location.nix
    ../../nixos/fontconfig.nix
    ../../nixos/persistence.nix
    ../../nixos/base.nix
    ../../nixos/i18n.nix
  ];

  # Configure nixos-facter to use the local facter.json
  facter.reportPath = ./facter.json;

  sops.defaultSopsFile = ../../secrets/common.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.secrets."shift_hashed_passwd" = {
    neededForUsers = true;
  };
  sops.secrets."shift_ssh_key" = {
    neededForUsers = true;
  };
  sops.secrets."cachix_api_key" = {
    neededForUsers = true;
  };
  sops.secrets."dio_hashed_passwd" = {
    neededForUsers = true;
    sopsFile = ../../secrets/shulkerbox/secrets.yaml;
  };
  sops.secrets."squeals_hashed_passwd" = {
    neededForUsers = true;
    sopsFile = ../../secrets/shulkerbox/secrets.yaml;
  };

  zramSwap.enable = true;

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
    # Lets have a nice boot seqence.
    plymouth = {
      enable = true;
      #      theme = lib.mkDefault "plymouth-matrix-theme";
    };
    extraModprobeConfig = ''
      options v4l2loopback devices=1 exclusive_caps=1 video_nr=5 card_label="OBS Cam"
    '';
  };

  #fileSystems."/persist".neededForBoot = true;

  stylix.cursor.package = lib.mkForce pkgs.bibata-cursors;
  stylix.cursor.name = lib.mkForce "Bibata-Modern-Ice";
  stylix.cursor = {
    size = lib.mkForce 26;
  };

  services.tlp.enable = true;
  services.power-profiles-daemon.enable = lib.mkForce false;
  services.fprintd.enable = true;

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

  networking = {
    hostName = "shulkerbox";
    wireless.dbusControlled = true;
    networkmanager = {
      enable = true;
    };
  };

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
      max-jobs = lib.mkForce 1;
      system-features = [
        "benchmark"
        "big-parallel"
        "kvm"
        "nixos-test"
      ];
    };
  };

  powerManagement = {
    enable = true;
    cpuFreqGovernor = "schedutil";
    powertop.enable = true;
  };

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gtk
    ];
  };

  # Yubikey support
  services.udev.packages = [ pkgs.yubikey-personalization ];
  security = {
    tpm2 = {
      enable = true;
      pkcs11.enable = true;
      tctiEnvironment.enable = true;
    };
    polkit.enable = true;
    rtkit.enable = true;
    pam = {
      loginLimits = [
        {
          domain = "@users";
          item = "rtprio";
          type = "-";
          value = 1;
        }
      ];
      yubico = {
        enable = true;
        debug = false;
        mode = "challenge-response";
      };
    };
  };
  services = {
    avahi = {
      enable = true;
      nssmdns4 = true;
    };

    journald.extraConfig = ''
      SystemMaxUse=256M
    '';
    tumbler.enable = true;
    acpid.enable = true;
    flatpak.enable = true;
    dbus = {
      enable = true;
      implementation = "broker";
      packages = [
        pkgs.gcr
      ];
    };

    accounts-daemon.enable = true;
    blueman.enable = true;
    greetd = {
      enable = true;
      settings.background.fit = "Fill";
    };

    fwupd.enable = true;
    udisks2.enable = true;
    upower.enable = true;

    # Configure keymap in X11
    xserver = {
      xkb = {
        layout = lib.mkForce "us";
        options = "eurosign:e,ctrl:nocaps,ctrl:swapcaps";
      };
    };
    libinput.enable = true;
    xserver.desktopManager.cinnamon.enable = true;

    # Enable CUPS to print documents.
    printing.enable = true;

    # Enable pipewire not ALSA for audio.
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };

    tailscale = {
      enable = false;
      useRoutingFeatures = "both";
      extraUpFlags = [
        "--ssh"
        "--advertise-exit-node"
        "--exit-node"
      ];
    };

  };
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.sessionVariables.WLR_RENDERER = "vulkan";
  environment.sessionVariables.ELECTRON_OZONE_PLATFORM_HINT = "wayland";

  nixpkgs.config.allowUnfree = false;
  nixpkgs.config.permittedInsecurePackages = [
    # "electron-25.9.0"
    # "python-2.7.18.8"
  ];

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  console = {
    keyMap = lib.mkForce "us";
    useXkbConfig = true; # use xkb.options in tty.
  };

  location.provider = "geoclue2";

  programs.regreet = {
    enable = true;

    settings = {
    };

  };
  # Lets have tmux.
  programs.tmux.enable = true;

  virtualisation.podman.enable = true;

  programs.sway.enable = true;
  programs.sway.wrapperFeatures.gtk = true;
  programs.sway.package = pkgs.swayfx;
  programs.sway.extraSessionCommands = ''
    # SDL:
    export SDL_VIDEODRIVER=wayland
    # QT (needs qt5.qtwayland in systemPackages):
    export QT_QPA_PLATFORM=wayland-egl
    export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
    # Fix for some Java AWT applications (e.g. Android Studio),
    # use this if they aren't displayed properly:
    export _JAVA_AWT_WM_NONREPARENTING=1
    export MOZ_ENABLE_WAYLAND=1
    export SAL_USE_VCLPLUGIN=gtk3
    # Use devices physical DPI.
    export QT_WAYLAND_FORCE_DPI=physical
    export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
  '';

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.mutableUsers = false;
  users.users.dio = {
    hashedPasswordFile = config.sops.secrets."dio_hashed_passwd".path;
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "input"
      "render"
      "video"
      "dialout"
      "podman"
      "scanner"
      "lp"
      "adbusers"
      "disk"
      "networkmanager"
      "children"
      "tss"
    ];
  };

  users.users.squeals = {
    hashedPasswordFile = config.sops.secrets."squeals_hashed_passwd".path;
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "input"
      "render"
      "video"
      "dialout"
      "podman"
      "scanner"
      "lp"
      "adbusers"
      "disk"
      "networkmanager"
      "children"
      "tss"
    ];
  };

  users.users.shift = {
    hashedPasswordFile = config.sops.secrets."shift_hashed_passwd".path;
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "input"
      "render"
      "video"
      "dialout"
      "podman"
      "scanner"
      "lp"
      "adbusers"
      "disk"
      "networkmanager"
      "tss"
    ];
    shell = "${pkgs.zsh}/bin/zsh";
  };
  users.defaultUserShell = pkgs.zsh;

  programs.zsh.enable = true;

  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="1949", ATTR{idProduct}=="0588", MODE="0666", GROUP="adbusers"
    SUBSYSTEM=="usb", ATTR{idVendor}=="1949", ATTR{idProduct}=="0282", MODE="0666", GROUP="adbusers"
  '';

  environment.systemPackages = with pkgs; [
    ssh-tpm-agent
    keyutils
    (inkscape-with-extensions.override {
      inkscapeExtensions = [
        inkscape-extensions.inkstitch
      ];
    })
    iw
    ethtool
    usbutils
    pciutils
    wol
    nmap
    iperf3
    plymouth
    browsh
    qt5.qtwayland
    SDL_compat
    android-tools
    android-udev-rules
    glfw-wayland
    greetd.regreet
    neovim
    cage
    git
    gotop
    htop
    lm_sensors
    intel-gpu-tools
    irqbalance
    libcec
    wireplumber
    sbctl
    gsettings-desktop-schemas
    dracula-theme
    pinentry-qt
    showmethekey
    libGL
    lisgd
    sway
    font-awesome
    ccid
    acsccid
    pcscliteWithPolkit
    pcsc-tools
    pkgs-unstable.pbpctrl
    pkgs-unstable.sops
    yubikey-personalization
    yubico-pam
    cryptsetup
    disko
  ];

  programs = {
    ssh.startAgent = lib.mkForce false;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage = pkgs.pinentry-qt;
    };

  };

  # List services that you want to enable:
  # Enable direnv and direnv-nix
  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = false;
  programs.adb.enable = true;
  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.settings.DenyGroups = [ "children" ];

  # Graphics configuration is now handled by nixos-facter
  # nixpkgs.config.packageOverrides = pkgs: {
  #   vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  # };
  # hardware.graphics = {
  #   enable = true;
  #   extraPackages = with pkgs; [
  #     intel-compute-runtime
  #     intel-media-driver
  #     vaapiVdpau
  #     libvdpau-va-gl
  #   ];
  # };

  home-manager.backupFileExtension = "backup";
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.shift = ../../users/shift/home.nix;
  home-manager.users.dio = ../../users/dio/home.nix;
  home-manager.users.squeals = ../../users/squeals/home.nix;

  documentation.nixos.enable = true;
  documentation.info.enable = true;
  documentation.doc.enable = true;

  services.grafana-alloy-laptop = {
    enable = true;
    grafanaCloud = {
      url = "https://prometheus-prod-01-eu-west-0.grafana.net/api/prom/push";
      username = "12345";
      password = "your-api-key-here";
    };
    textfileCollector.enable = true;
  };
  # If the geoclue module is enabled, it will auto-register with alloy
  services.geoclue-prometheus-exporter = {
    enable = true;
    bind = "127.0.0.1";
    port = 9090;

    # Optional: you can disable the auto-registration
    # registerWithAlloy = false;
  };

  system.stateVersion = "25.05";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
