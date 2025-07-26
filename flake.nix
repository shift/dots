{
  description = "DOTS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    impermanence.url = "github:nix-community/impermanence";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    comin = {
      url = "github:nlewo/comin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Software inputs
    dots-notifier = {
      url = "github:shift/dots-notifier";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dots-wallpaper = {
      url = "github:shift/dots-wallpaper";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    geoclue-prometheus-exporter = {
      url = "github:shift/geoclue-prometheus-exporter";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixd = {
      url = "github:nix-community/nixd";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-minecraft = {
      url = "github:Infinidoge/nix-minecraft";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # BLING!
    stylix.url = "github:nix-community/stylix/release-25.05";
    stylix.inputs.nixpkgs.follows = "nixpkgs";

    # Devshell
    treefmt-nix.url = "github:numtide/treefmt-nix";

  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nixpkgs-unstable,
      nixos-hardware,
      lanzaboote,
      impermanence,
      home-manager,
      nixvim,
      nixos-generators,
      disko,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs-unstable = nixpkgs-unstable.legacyPackages.x86_64-linux;
    in
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
        "aarch64-linux"
      ];
      imports = [
        inputs.treefmt-nix.flakeModule
        nixos-generators.nixosModules.all-formats
        ./nixos
      ];

      flake = {

        # Configurations for Linux (NixOS) systems
        nixosConfigurations = {
          shulkerbox = nixpkgs.lib.nixosSystem {
            specialArgs = {
              inherit inputs;
              inherit pkgs-unstable;
            };

            modules = [
              # Add any other custom nixos-hardware modules required here.
              nixos-hardware.nixosModules.lenovo-thinkpad-x250
              nixos-hardware.nixosModules.common-pc-ssd
              # The following is used for partitioning of drives during the installation.
              inputs.disko.nixosModules.disko
              impermanence.nixosModules.impermanence
              inputs.sops-nix.nixosModules.sops
              inputs.comin.nixosModules.comin
              home-manager.nixosModules.home-manager
              nixvim.nixosModules.nixvim
              inputs.stylix.nixosModules.stylix
              inputs.geoclue-prometheus-exporter.nixosModules.default
              inputs.dots-notifier.nixosModules.x86_64-linux.notifier
              {
                nixpkgs.config.allowUnfree = true;
                stylix.enable = true;
                stylix.autoEnable = true;
                stylix.image = ./assets/wallpaper.jpg;
                stylix.targets.plymouth.logo = ./assets/wallpaper.jpg;
                stylix.targets.plymouth.logoAnimated = false;
                stylix.polarity = "dark";

                stylix.opacity = {
                  terminal = 0.5;
                  popups = 0.5;
                  desktop = 0.5;
                };
                stylix.targets.grub.useImage = true;
                fileSystems."/persist".neededForBoot = true;

                #services.btrfs.autoScrub.enable = true;
                services.qemuGuest.enable = true;
              }
              ./modules
              inputs.dots-wallpaper.nixosModules.default
              {
                dots.wallpaper = {
                  enable = true;
                  width = 1366; # Configure for your screen
                  height = 768; # Configure for your screen
                  flakeRootDefault = ./assets/wallpaper.jpg;
                };
              }
              ./disks/shulkerbox/disko.nix
              ./hosts/shulkerbox.nix
              ./nixos/secureboot.nix
              ./nixos/comin.nix
              ./nixos/ssh-tpm-agent.nix
              ./nixos/laptop/suspend-and-hibernate.nix
            ];
          };

          shulkerbox-installer = nixpkgs.lib.nixosSystem {

            specialArgs = {
              inherit inputs;
              inherit pkgs-unstable;
            };

            inherit system;
            modules = [
              "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
              nixos-hardware.nixosModules.common-cpu-intel
              nixos-hardware.nixosModules.common-pc-ssd
              impermanence.nixosModules.impermanence
              lanzaboote.nixosModules.lanzaboote
              (
                {
                  pkgs,
                  lib,
                  ...
                }:
                {
                  # Ensure this is a NixOS ISO configuration
                  #boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;
                  #boot.zfs.enabled = lib.mkForce false;

                  # Networking for installation
                  networking = {
                    networkmanager.enable = true;
                    wireless.enable = false;
                  };

                  # Essential tools for installation
                  environment.systemPackages = with pkgs; [
                    git
                    vim
                    wget
                    curl
                    nixos-anywhere
                    disko
                    sbctl
                    util-linux
                    xxd
                    file
                    openssh
                    # Interactive TUI tools
                    gum
                    bun # For interactive guidance
                    # TPM and hardware detection
                    tpm2-tools # Fixed typo from tmp2-tools
                    dmidecode
                    lshw
                    # Archive and compression tools
                    p7zip
                    # SOPS and secure boot tools
                    sops
                    # SOPS and SSH-to-AGE tools for new host setup
                    sops
                    ssh-to-age
                    qrencode # For QR code generation
                  ];

                  # Pre-populate the Nix store with packages needed for the target system
                  # Benefits:
                  # - Enables completely offline installation
                  # - Faster installation (no downloads during install)
                  # - Reliable installation in environments with poor connectivity
                  # - Self-contained installer with everything needed
                  #
                  # Note: This will make the ISO significantly larger (~2-4GB instead of ~800MB)
                  # but provides a complete offline installation experience.
                  isoImage.storeContents = [
                    # Include the full system closure for shulkerbox
                    self.nixosConfigurations.shulkerbox.config.system.build.toplevel

                    # Include commonly needed packages
                    pkgs.git
                    pkgs.vim
                    pkgs.neovim
                    pkgs.firefox
                    pkgs.home-manager

                    # Include all packages from our custom modules
                    pkgs.ssh-tpm-agent
                    pkgs.keyutils
                    (pkgs.inkscape-with-extensions.override {
                      inkscapeExtensions = [
                        pkgs.inkscape-extensions.inkstitch
                      ];
                    })
                    pkgs.browsh
                    pkgs.SDL_compat
                    pkgs.android-tools
                    pkgs.android-udev-rules
                    pkgs.qt5.qtwayland
                    pkgs.glfw-wayland
                    pkgs.greetd.regreet
                    pkgs.cage
                    pkgs.gotop
                    pkgs.htop
                    pkgs.lm_sensors
                    pkgs.intel-gpu-tools
                    pkgs.irqbalance
                    pkgs.libcec
                    pkgs.wireplumber
                    pkgs.sbctl
                    pkgs.gsettings-desktop-schemas
                    pkgs.dracula-theme
                    pkgs.pinentry-qt
                    pkgs.showmethekey
                    pkgs.libGL
                    pkgs.lisgd
                    pkgs.sway
                    pkgs.font-awesome
                    pkgs.ccid
                    pkgs.acsccid
                    pkgs.pcscliteWithPolkit
                    pkgs.pcsc-tools
                    pkgs-unstable.pbpctrl
                    pkgs-unstable.sops
                    pkgs.yubikey-personalization
                    pkgs.yubico-pam
                    pkgs.cryptsetup
                    pkgs.disko

                    # Desktop environment packages
                    pkgs.bibata-cursors
                    pkgs.plymouth
                    pkgs.plymouth-matrix-theme

                    # Development tools
                    pkgs.nixfmt-rfc-style
                    pkgs.treefmt

                    # Hardware support
                    pkgs.hplipWithPlugin
                    pkgs.sane-airscan

                    # Network tools
                    pkgs.iw
                    pkgs.ethtool
                    pkgs.usbutils
                    pkgs.pciutils
                    pkgs.wol
                    pkgs.nmap
                    pkgs.iperf3

                    # Audio and media
                    pkgs.pipewire
                    pkgs.wireplumber
                    pkgs.alsa-lib
                    pkgs.pulseaudio

                    # Graphics and display
                    pkgs.mesa
                    pkgs.xorg.xf86videointel
                    pkgs.intel-media-driver
                    pkgs.intel-compute-runtime
                    pkgs.vaapiIntel
                    pkgs.libvdpau-va-gl

                    # Fonts
                    pkgs.fira-code
                    pkgs.fira-code-symbols
                    pkgs.noto-fonts
                    pkgs.noto-fonts-cjk-sans
                    pkgs.noto-fonts-emoji
                    pkgs.material-design-icons

                    # System utilities
                    pkgs.systemd
                    pkgs.udev
                    pkgs.polkit
                    pkgs.networkmanager
                    pkgs.bluez
                    pkgs.blueman

                    # Wayland/Sway ecosystem
                    pkgs.waybar
                    pkgs.swaylock
                    pkgs.swayidle
                    pkgs.wl-clipboard
                    pkgs.grim
                    pkgs.slurp
                    pkgs.fuzzel
                    pkgs.foot

                    # Essential system libraries
                    pkgs.glibc
                    pkgs.gcc
                    pkgs.binutils
                    pkgs.coreutils
                    pkgs.findutils
                    pkgs.gnugrep
                    pkgs.gnused
                    pkgs.gnutar
                    pkgs.gzip
                    pkgs.bzip2
                    pkgs.xz
                  ];

                  # SSH for remote access
                  services.openssh = {
                    enable = true;
                    settings = {
                      PermitRootLogin = "yes";
                      PasswordAuthentication = true;
                    };
                  };

                  # Temporary root access (override any conflicting password settings)
                  users.users.root = {
                    initialPassword = lib.mkForce "nixos"; # CHANGE IMMEDIATELY
                    openssh.authorizedKeys.keys = [
                      # Add your SSH public key here
                    ];
                  };

                  # Allow passwordless sudo
                  security.sudo.wheelNeedsPassword = false;

                  # Ensure installer scripts are executable
                  system.activationScripts.makeInstallerScriptsExecutable = ''
                    if [ -d /installer-scripts ]; then
                      chmod +x /installer-scripts/*.sh
                      # Create convenient symlinks in /usr/local/bin
                      mkdir -p /usr/local/bin
                      ln -sf /installer-scripts/shulker-autoinstall.sh /usr/local/bin/shulker-install
                      ln -sf /installer-scripts/detect-setup-mode.sh /usr/local/bin/check-setup-mode
                      ln -sf /installer-scripts/install-secureboot-keys.sh /usr/local/bin/install-secureboot
                    fi
                  '';

                  # ISO-specific configuration
                  system.stateVersion = lib.mkForce "25.05";

                  # Create convenient aliases for installer scripts
                  environment.shellAliases = {
                    shulker-install = "/installer-scripts/shulker-autoinstall.sh";
                    shulker-status = "/installer-scripts/shulker-autoinstall.sh status";
                    setup-sops = "/installer-scripts/shulker-autoinstall.sh setup-sops";
                    install-secureboot = "/installer-scripts/install-secureboot-keys.sh";
                    check-setup-mode = "/installer-scripts/detect-setup-mode.sh";
                  };

                  # Add installer message to motd
                  users.motd = ''
                    Welcome to Shulker Installer!

                    Quick Commands:
                      shulker-install     - Full automated installation
                      shulker-status      - Check system status
                      setup-sops          - Set up SOPS for new host (with QR code)
                      install-secureboot  - Install secure boot keys
                      check-setup-mode    - Check if in setup mode

                    For help: shulker-install --help
                  '';

                  # Optional auto-installer service (disabled by default)
                  systemd.services.shulker-auto-installer = {
                    description = "Shulker Auto Installer Service";
                    wantedBy = [ ]; # Disabled by default - enable with: systemctl enable shulker-auto-installer
                    after = [ "network-online.target" ];
                    wants = [ "network-online.target" ];
                    serviceConfig = {
                      Type = "oneshot";
                      ExecStart = "/installer-scripts/shulker-autoinstall.sh install";
                      StandardOutput = "journal+console";
                      StandardError = "journal+console";
                    };
                  };

                  # Explicitly configure the ISO image
                  isoImage = {
                    # Customize ISO naming
                    isoName = "shulkerbox-installer-${lib.substring 0 8 (self.rev or "dirty")}.iso";
                    # The following is a trade off of time vs size. 3 seems to give a rather decent compressioon given the time it takes.
                    squashfsCompression = "zstd -Xcompression-level 3";
                    # Add current repository to the ISO
                    contents = [
                      {
                        source = ./.;
                        target = "/repo";
                      }
                      {
                        source = ./installer-scripts;
                        target = "/installer-scripts";
                      }
                      {
                        source = ./secrets/secureboot;
                        target = "/secureboot";
                      }
                    ];
                  };
                }
              )
              inputs.sops-nix.nixosModules.sops
              home-manager.nixosModules.home-manager
              nixvim.nixosModules.nixvim
              inputs.stylix.nixosModules.stylix
              {
                nixpkgs.config.allowUnfree = true;
                stylix.enable = true;
                stylix.autoEnable = true;
                stylix.image = ./assets/wallpaper.jpg;
                stylix.targets.plymouth.logo = ./assets/wallpaper.jpg;
                stylix.targets.plymouth.logoAnimated = false;
                stylix.polarity = "dark";

                stylix.opacity = {
                  terminal = 0.95;
                  popups = 0.95;
                  desktop = 0.5;
                };
                stylix.targets.grub.useImage = true;

              }

              #./hosts/shulkerbox.nix
            ];
          };
        };
      };

      perSystem =
        {
          pkgs,
          system,
          ...
        }:
        {
          # NOTE: These overlays apply to the Nix shell only. See `nix.nix` for
          # system overlays.
          # _module.args.pkgs = import inputs.nixpkgs {
          #   inherit system;
          # };
          #
          # treefmt.config = {
          #   projectRootFile = "flake.nix";
          #   programs.nixpkgs-fmt.enable = true;
          # };
          #
          # packages.default = self'.packages.activate;

          packages = {
            # Signed installer ISO with Secure Boot signed EFI bootloaders
            shulkerbox-installer-signed =
              let
                baseIso = self.nixosConfigurations.shulkerbox-installer.config.system.build.isoImage;
                securebootKeys = ./secrets/secureboot/x1y;
              in
              pkgs.runCommand "shulkerbox-installer-signed-1.0.0"
                {
                  buildInputs = with pkgs; [
                    sbsigntool
                    sbctl
                    coreutils
                    util-linux
                    findutils
                    xorriso
                    dosfstools
                    mtools
                    squashfs-tools-ng
                    cdrkit # provides genisoimage
                  ];
                  meta = with pkgs.lib; {
                    description = "Shulkerbox installer ISO with Secure Boot signed EFI bootloaders";
                    license = licenses.mit;
                    platforms = platforms.linux;
                  };
                }
                ''
                  echo "Preparing ISO with signed EFI bootloaders..."

                  # Find the ISO file in the base build
                  isoFile=$(find ${baseIso} -name "*.iso" -type f | head -1)
                  if [ -z "$isoFile" ]; then
                    echo "Error: No ISO file found in base build"
                    echo "Contents of ${baseIso}:"
                    find ${baseIso} -type f | head -10
                    exit 1
                  fi

                  echo "Found ISO: $isoFile"
                  cp "$isoFile" ./original.iso

                  # Check if we have secureboot keys available
                  if [ -d "${securebootKeys}" ] && [ -f "${securebootKeys}/db/db.key" ] && [ -f "${securebootKeys}/db/db.pem" ]; then
                    echo "Secureboot keys found, extracting and signing EFI bootloaders..."
                    
                    # Create working directory
                    mkdir -p iso_extract efi_extract
                    
                    # Extract the ISO
                    echo "Extracting ISO contents..."
                    xorriso -osirrox on -indev original.iso -extract / iso_extract/
                    
                    # Find and extract the EFI system partition
                    efiImg=$(find iso_extract -name "efiboot.img" -type f | head -1)
                    if [ -z "$efiImg" ]; then
                      echo "Warning: No efiboot.img found, looking for other EFI images..."
                      efiImg=$(find iso_extract -name "*.img" -path "*/EFI*" -type f | head -1)
                    fi
                    
                    if [ -n "$efiImg" ]; then
                      echo "Found EFI image: $efiImg"
                      
                      # Mount the EFI image and extract contents
                      mkdir -p efi_mount
                      cp "$efiImg" ./efiboot.img
                      
                      # Extract FAT filesystem contents
                      mcopy -s -i ./efiboot.img :: efi_extract/ || true
                      
                      # Find and sign EFI executables
                      echo "Signing EFI executables..."
                      signed_count=0
                      find efi_extract -name "*.efi" -type f | while read efi_file; do
                        echo "Signing: $efi_file"
                        sbsign --key "${securebootKeys}/db/db.key" 
                               --cert "${securebootKeys}/db/db.pem" 
                               --output "$efi_file.signed" 
                               "$efi_file"
                        
                        if [ $? -eq 0 ]; then
                          mv "$efi_file.signed" "$efi_file"
                          signed_count=$((signed_count + 1))
                          echo "  ✓ Signed successfully"
                        else
                          echo "  ✗ Signing failed"
                        fi
                      done
                      
                      # Rebuild the EFI image with signed bootloaders
                      echo "Rebuilding EFI image with signed bootloaders..."
                      
                      # Create new FAT image
                      dd if=/dev/zero of=./efiboot_new.img bs=1M count=64
                      mkfs.vfat -F 32 ./efiboot_new.img
                      
                      # Copy signed files back
                      mcopy -s -i ./efiboot_new.img efi_extract/* ::
                      
                      # Replace the EFI image in the ISO contents
                      cp ./efiboot_new.img "$efiImg"
                      
                      echo "Rebuilding ISO with signed EFI bootloaders..."
                      
                      # Rebuild the ISO
                      xorriso -as mkisofs 
                        -iso-level 3 
                        -full-iso9660-filenames 
                        -volid "NIXOS_ISO" 
                        -eltorito-boot isolinux/isolinux.bin 
                        -eltorito-catalog isolinux/boot.cat 
                        -no-emul-boot 
                        -boot-load-size 4 
                        -boot-info-table 
                        -eltorito-alt-boot 
                        -e EFI/boot/efiboot.img 
                        -no-emul-boot 
                        -isohybrid-gpt-basdat 
                        -output installer-signed.iso 
                        iso_extract/ || {
                        
                        # Fallback: try simpler ISO creation
                        echo "Primary ISO rebuild failed, trying simpler method..."
                        genisoimage -r -J -b isolinux/isolinux.bin -c isolinux/boot.cat 
                          -no-emul-boot -boot-load-size 4 -boot-info-table 
                          -eltorito-alt-boot -e EFI/boot/efiboot.img -no-emul-boot 
                          -o installer-signed.iso iso_extract/ || {
                          
                          echo "ISO rebuild failed, copying original"
                          cp original.iso installer-signed.iso
                        }
                      }
                      
                    else
                      echo "No EFI image found in ISO, copying original"
                      cp original.iso installer-signed.iso
                    fi
                    
                  else
                    echo "No secureboot keys found, creating unsigned copy"
                    cp original.iso installer-signed.iso
                  fi

                  # Install outputs
                  mkdir -p $out
                  cp installer-signed.iso $out/

                  # Create a convenient symlink with a predictable name
                  ln -s installer-signed.iso $out/shulkerbox-installer-signed.iso

                  # Create metadata
                  cat > $out/build-info.txt << EOF
                  Shulkerbox Installer ISO with Signed EFI Bootloaders
                  System: ${system}
                  Base ISO: $(basename "$isoFile")
                  EFI Signed: $([ -f "${securebootKeys}/db/db.key" ] && echo "Yes" || echo "No")
                  Build: $(date)
                  EOF
                '';

          };

          devShells.default = pkgs.mkShell {
            buildInputs = [
              pkgs.git
              pkgs.nixpkgs-fmt
              pkgs.sops
              pkgs.ssh-to-age
              pkgs.nixfmt-rfc-style
              pkgs.treefmt
              pkgs.nixos-generators
            ];
          };

          treefmt = {
            # Used to find the project root
            projectRootFile = "flake.nix";

            programs = {
              nixfmt.enable = pkgs.lib.meta.availableOn pkgs.stdenv.buildPlatform pkgs.nixfmt-rfc-style.compiler;

              nixfmt.package = pkgs.nixfmt-rfc-style;
              shellcheck.enable = true;
              shfmt.enable = true;
              # Respect editorconfig
              shfmt.indent_size = null;
              statix.enable = true;
              deadnix.enable = true;
              prettier.enable = true;
              taplo.enable = true;
            };
            settings = {
              global.excludes = [
                "*.lock"
                "*.rst"
                "*.md"
                "*.png"
                "*.po"
                "*.mp3"
                "*.yaml"
              ];
              formatter = {
                # Doesn't support setext headers amongst other things
                prettier.excludes = [ "*.md" ];
                shellcheck = {
                  excludes = [
                    ".envrc"
                    "quodlibet.bash"
                  ];
                };
              };
            };
          };
        };
    };
}
