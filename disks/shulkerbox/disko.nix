{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/sda"; # Make sure this is the correct disk you intend to format!
        content = {
          type = "gpt"; # Use GUID Partition Table

          partitions = {
            # EFI System Partition (ESP) for bootloader files
            ESP = {
              name = "ESP"; # Partition label
              size = "512M"; # 512 Megabytes in size
              type = "EF00"; # Standard type code for an ESP
              content = {
                type = "filesystem";
                format = "vfat"; # FAT32 filesystem, standard for ESP
                mountpoint = "/boot"; # Mount it at /boot
              };
            };

            # LUKS encrypted partition containing BTRFS
            luks = {
              name = "luks"; # Partition label
              # This is the corrected line:
              # "100%" means this partition will take up all remaining space on the disk
              # after the ESP partition.
              size = "100%";
              content = {
                type = "luks";
                name = "crypted"; # Name for the LUKS container (e.g., /dev/mapper/crypted)
                # LUKS settings. fido2 and tpm2 settings are for keyless decryption.
                settings = {
                  allowDiscards = true; # Enables TRIM/discard for SSDs
                  bypassWorkqueues = true; # Can improve performance on some NVMe drives
                  # fido2.gracePeriod = 10; # Optional: grace period for FIDO2 device
                  # crypttabExtraOpts = [ # Options passed to crypttab
                  #   "fido2-device=auto"
                  #   "tpm2-device=auto"
                  #   "token-timeout=10" # Timeout for token input
                  # ];
                  # Note: If you don't have FIDO2/TPM configured or don't want to use them at install time,
                  # you might want to comment out or adjust the fido2 and tpm2 related settings
                  # to avoid potential issues if the hardware/setup isn't ready for them.
                  # For a simpler setup, you can remove fido2 and crypttabExtraOpts initially.
                };
                content = {
                  type = "btrfs";
                  # BTRFS subvolumes. These are like flexible partitions within the BTRFS filesystem.
                  subvolumes = {
                    # Root filesystem
                    "/root" = {
                      mountpoint = "/";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ]; # Enable compression and disable access time updates
                    };
                    # Nix store
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                    # Persistent storage (e.g., for data you want to survive rollbacks if not part of home)
                    # Ensure you have a strategy for what goes into /persist.
                    # For example, you might symlink directories from /var/log or /etc/ssh here.
                    "/persist" = {
                      mountpoint = "/persist";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                    # Subvolume for the swap file
                    # Using a BTRFS subvolume for swap is a common pattern.
                    "/swap" = {
                      mountpoint = "/.swapvol"; # Mount point for the subvolume (can be hidden)
                      swap.swapfile.size = "16G";
                      # Create a 16GB swap file within this subvolume
                      # Ensure your disk has enough space for this + OS + data.
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
