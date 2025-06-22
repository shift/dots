# Host Configuration with Factor Files

This directory implements a factor-based host configuration system that allows for data-driven configuration management.

## Structure

```
hosts/
├── default.nix          # Entry point for dynamic host discovery
├── lib.nix              # Utilities for factor-based configuration
└── <hostname>/
    ├── default.nix      # Host-specific configuration
    └── factor.json      # Host metadata and feature configuration
```

## Factor File Format

The `factor.json` file contains structured metadata about the host's hardware and desired features:

```json
{
  "stateVersion": "25.05",
  "hostPlatform": "x86_64-linux",
  "hardware": {
    "cpu": {
      "architecture": "x86_64",
      "governor": "schedutil",
      "features": ["benchmark", "big-parallel", "kvm", "nixos-test"]
    },
    "gpu": {
      "vendor": "intel",
      "graphics": {
        "enable": true,
        "extraPackages": ["intel-compute-runtime", "intel-media-driver", "vaapiVdpau", "libvdpau-va-gl"]
      }
    },
    "memory": {
      "zramSwap": true
    }
  },
  "features": {
    "bluetooth": {
      "enable": true,
      "powerOnBoot": true
    },
    "wifi": {
      "enable": true,
      "networkmanager": true,
      "dbusControlled": true
    },
    "graphics": {
      "enable": true
    },
    "fingerprint": {
      "enable": true
    },
    "scanner": {
      "enable": true
    },
    "tlp": {
      "enable": true
    }
  },
  "nix": {
    "maxJobs": 1,
    "optimise": {
      "automatic": true,
      "dates": ["03:45"]
    },
    "gc": {
      "automatic": true,
      "dates": "weekly",
      "options": "--delete-older-than 30d"
    }
  }
}
```

## How It Works

1. **Factor Loading**: The `lib.nix` utility reads the `factor.json` file for each host
2. **Configuration Generation**: Based on the factor data, appropriate NixOS configuration options are generated
3. **Dynamic Import**: The host's `default.nix` imports both static configuration and the dynamically generated factor-based configuration
4. **Fallback**: If no factor file exists, safe defaults are used

## Benefits

- **Declarative Hardware Description**: Hardware capabilities and features are described in a structured format
- **Reduced Duplication**: Common patterns are centralized in the factor system
- **Easier Scaling**: Adding new hosts requires minimal boilerplate - just define their factors
- **Consistent Configuration**: All hosts follow the same factor-based structure
- **Version Control Friendly**: Factor files are human-readable JSON that's easy to diff and review

## Usage

To create a new host:

1. Create a directory under `hosts/` with the hostname
2. Add a `factor.json` file describing the hardware and features
3. Create a `default.nix` that imports the factor configuration:

```nix
{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:
let
  hostUtils = import ../lib.nix { inherit lib pkgs; };
  factorConfig = hostUtils.mkHostConfig ./.;
in
{
  imports = [
    # Your base modules
  ] ++ [ factorConfig ];

  # Host-specific configuration that isn't covered by factors
  networking.hostName = "yourhostname";
  # ...
}
```

The factor system will automatically apply the appropriate configuration based on the JSON metadata.