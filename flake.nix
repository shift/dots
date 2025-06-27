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
    sops-nix.url = "github:Mic92/sops-nix";
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
    };
    geoclue-prometheus-exporter = {
      url = "github:shift/geoclue-prometheus-exporter";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim.url = "github:nix-community/nixvim/nixos-25.05";
    nixd.url = "github:nix-community/nixd";
    nix-minecraft = {
      url = "github:Infinidoge/nix-minecraft";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # BLING!
    stylix.url = "github:nix-community/stylix/release-25.05";
    stylix.inputs.nixpkgs.follows = "nixpkgs";
    stylix.inputs.home-manager.follows = "home-manager";

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
                #stylix.image = ./assets/wallpaper.jpg;
                #stylix.targets.plymouth.logo = ./assets/wallpaper.jpg;
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
              ./modules/wallpaper.nix
              {
                dots.wallpaper = {
                  enable = true;
                  width = 2560; # Configure for your screen
                  height = 1440; # Configure for your screen
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
                    tpm2-tools
                    dmidecode
                    lshw
                    # Archive and compression tools
                    p7zip
                    # SOPS and secure boot tools
		    sbctl
                    sops
                    # SOPS and SSH-to-AGE tools for new host setup
                    sops
                    ssh-to-age
                    qrencode # For QR code generation
                  ];

                  # SSH for remote access
                  services.openssh = {
                    enable = true;
                    settings = {
                      PermitRootLogin = "yes";
                      PasswordAuthentication = true;
                    };
                  };

                  # Temporary root access
                  users.users.root = {
                    password = "nixos"; # CHANGE IMMEDIATELY
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
                        source = /etc/ssh;
                        target = "/ssh_keys";
                      }
                      {
                        source = /etc/secureboot;
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
            # Signed installer ISO with Secure Boot keys
            shulkerbox-installer-signed = 
              let
                baseIso = self.nixosConfigurations.shulkerbox-installer.config.system.build.isoImage;
                securebootKeys = ./secrets/secureboot/x1y;
              in
              pkgs.stdenv.mkDerivation rec {
                pname = "shulkerbox-installer-signed";
                version = "1.0.0";

                src = baseIso;

                buildInputs = with pkgs; [
                  sbsigntools
                  coreutils
                  util-linux
                ];

                buildPhase = ''
                  echo "Preparing ISO for signing..."
                  
                  # Find the ISO file
                  isoFile=$(find $src -name "*.iso" | head -1)
                  if [ -z "$isoFile" ]; then
                    echo "Error: No ISO file found in base build"
                    exit 1
                  fi
                  
                  echo "Found ISO: $isoFile"
                  cp "$isoFile" ./installer.iso
                  
                  # Check for Secure Boot keys
                  if [ -f "${securebootKeys}/db/db.key" ] && [ -f "${securebootKeys}/db/db.pem" ]; then
                    echo "Signing ISO with Secure Boot keys..."
                    
                    # Sign the ISO
                    sbsign \
                      --key "${securebootKeys}/db/db.key" \
                      --cert "${securebootKeys}/db/db.pem" \
                      --output installer-signed.iso \
                      installer.iso
                    
                    echo "✅ ISO signed successfully with Secure Boot keys!"
                  else
                    echo "⚠️  Warning: Secure Boot keys not found at ${securebootKeys}"
                    echo "Creating unsigned copy..."
                    cp installer.iso installer-signed.iso
                  fi
                '';

                installPhase = ''
                  mkdir -p $out
                  cp installer-signed.iso $out/
                  
                  # Create a convenient symlink with a predictable name
                  ln -s installer-signed.iso $out/shulkerbox-installer-signed.iso
                  
                  # Create metadata
                  cat > $out/build-info.txt << EOF
                  Shulkerbox Installer ISO (Secure Boot Signed)
                  Built: $(date)
                  System: ${system}
                  Base ISO: $(basename "$src")
                  Signed: $(test -f "${securebootKeys}/db/db.key" && echo "Yes" || echo "No")
                  EOF
                '';

                meta = with pkgs.lib; {
                  description = "Shulkerbox installer ISO with Secure Boot signing";
                  license = licenses.mit;
                  platforms = platforms.linux;
                };
              };
          };

          devShells.default = pkgs.mkShell {
            buildInputs = [
              pkgs.git
              pkgs.nixpkgs-fmt
              pkgs.sops
              pkgs.ssh-to-age
              pkgs.nixfmt-rfc-style
              pkgs.treefmt2
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
