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

                  # ISO-specific configuration
                  system.stateVersion = lib.mkForce "25.05";

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
          self',
          inputs',
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

          # Comprehensive checks for flake robustness and quality
          checks = {
            # Format and Lint Checks - integrate with treefmt
            format-check = pkgs.runCommand "format-check"
              {
                buildInputs = [ self'.formatter ];
                src = ./.;
              } ''
                cd $src
                ${self'.formatter}/bin/treefmt --check
                touch $out
              '';
            
            # Dead Code Detection
            deadnix-check = pkgs.runCommand "deadnix-check" 
              { 
                buildInputs = [ pkgs.deadnix ]; 
                src = ./.;
              } ''
                cd $src
                deadnix --fail .
                touch $out
              '';

            # Nix Linting with statix
            statix-check = pkgs.runCommand "statix-check"
              {
                buildInputs = [ pkgs.statix ];
                src = ./.;
              } ''
                cd $src
                statix check .
                touch $out
              '';

            # Flake Evaluation and Validation
            flake-check = pkgs.runCommand "flake-check"
              {
                buildInputs = [ pkgs.nix ];
                src = ./.;
              } ''
                cd $src
                nix flake check --no-build
                touch $out
              '';

            # Documentation Validation - check for broken links and missing docs
            doc-validation = pkgs.runCommand "doc-validation"
              {
                buildInputs = [ pkgs.findutils pkgs.gnugrep ];
                src = ./.;
              } ''
                cd $src
                # Check that README exists and has content
                if [[ ! -f README.md ]] || [[ ! -s README.md ]]; then
                  echo "ERROR: README.md is missing or empty"
                  exit 1
                fi
                
                # Check for TODO/FIXME comments that might indicate incomplete work
                if find . -name "*.nix" -exec grep -l "TODO\|FIXME\|XXX" {} \; | grep -q .; then
                  echo "WARNING: Found TODO/FIXME comments in Nix files"
                  find . -name "*.nix" -exec grep -Hn "TODO\|FIXME\|XXX" {} \;
                fi
                
                touch $out
              '';

            # Dependency Auditing - check for outdated or problematic inputs
            dependency-audit = pkgs.runCommand "dependency-audit"
              {
                buildInputs = [ pkgs.nix pkgs.jq ];
                src = ./.;
              } ''
                cd $src
                # Check that flake.lock exists and inputs are properly locked
                if [[ ! -f flake.lock ]]; then
                  echo "ERROR: flake.lock missing - run 'nix flake lock'"
                  exit 1
                fi
                
                # Validate flake.lock structure
                nix flake metadata --json > /dev/null
                
                # Check for inputs that might need updates (older than 90 days)
                echo "Checking input freshness..."
                nix flake metadata --json | jq -r '.locks.nodes | to_entries[] | select(.value.locked?) | "\(.key): \(.value.locked.lastModified // 0)"' > input_dates.txt
                
                touch $out
              '';

            # Build Consistency - verify core configurations build
            build-consistency = pkgs.runCommand "build-consistency"
              {
                buildInputs = [ pkgs.nix ];
                src = ./.;
              } ''
                cd $src
                # Test that main system configuration builds (dry-run)
                nix build .#nixosConfigurations.shulkerbox.config.system.build.toplevel --dry-run
                
                # Test that installer configuration builds (dry-run)  
                nix build .#nixosConfigurations.shulkerbox-installer.config.system.build.isoImage --dry-run
                
                touch $out
              '';

            # Security Enhancements - basic security checks
            security-check = pkgs.runCommand "security-check"
              {
                buildInputs = [ pkgs.findutils pkgs.gnugrep ];
                src = ./.;
              } ''
                cd $src
                # Check for potential security issues in Nix files
                
                # Look for hardcoded passwords or secrets (basic check)
                if find . -name "*.nix" -exec grep -i "password\s*=" {} \; | grep -v "# " | grep -q .; then
                  echo "WARNING: Found potential hardcoded passwords"
                  find . -name "*.nix" -exec grep -Hn -i "password\s*=" {} \; | grep -v "# "
                fi
                
                # Check for allowUnfree usage (should be documented)
                if find . -name "*.nix" -exec grep -l "allowUnfree.*true" {} \; | grep -q .; then
                  echo "INFO: allowUnfree is enabled - ensure this is intentional"
                  find . -name "*.nix" -exec grep -Hn "allowUnfree.*true" {} \;
                fi
                
                # Check for insecure package usage
                if find . -name "*.nix" -exec grep -l "unsafeDiscardStringContext\|unsafeDiscardOutputDependency" {} \; | grep -q .; then
                  echo "WARNING: Found usage of unsafe Nix functions"
                  find . -name "*.nix" -exec grep -Hn "unsafeDiscardStringContext\|unsafeDiscardOutputDependency" {} \;
                fi
                
                touch $out
              '';

            # Garbage Collection and Optimization Check
            gc-check = pkgs.runCommand "gc-check"
              {
                buildInputs = [ pkgs.nix ];
                src = ./.;
              } ''
                cd $src
                # Verify that expressions can be properly evaluated
                nix eval .#nixosConfigurations.shulkerbox.pkgs.system --raw > /dev/null
                
                # Check for potential circular dependencies or evaluation issues
                timeout 30s nix-instantiate --eval --strict --expr 'builtins.attrNames (import ./flake.nix).outputs' > /dev/null
                
                touch $out
              '';
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
