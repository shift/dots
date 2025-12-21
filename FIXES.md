# Fix for users/dio/home.nix infinite recursion error

## Problem Analysis
The issue is that `users/dio/home.nix` expects an `inputs'` parameter to access the dots framework, but the home-manager configuration in `hosts/shulkerbox.nix` doesn't provide this argument, causing infinite recursion when trying to resolve `inputs'` through `_module.args`.

## Root Cause
- `dio/home.nix:1` defines `{ inputs', pkgs, ... }:` expecting `inputs'` to be passed
- `hosts/shulkerbox.nix:476` assigns `home-manager.users.dio = ./../users/dio/home.nix;` without providing `inputs'`
- This causes Nix to try to resolve `inputs'` through the module system, leading to infinite recursion

## Solution Options

### Option 1: Add inputs' to home-manager configuration (Recommended)
Modify `hosts/shulkerbox.nix` to pass `inputs'` to all user home configurations:

```nix
home-manager.users = {
  shift = import ../users/shift/home.nix;
  dio = { inputs', pkgs, ... }: import ../users/dio/home.nix { inherit inputs' pkgs; };
  squeals = import ../users/squeals/home.nix;
};
```

### Option 2: Use specialArgs for home-manager
Add `inputs'` to home-manager's specialArgs so all user configs can access it:

```nix
home-manager = {
  useGlobalPkgs = true;
  useUserPackages = true;
  specialArgs = { inherit inputs'; };
  users = {
    shift = ../users/shift/home.nix;
    dio = ../users/dio/home.nix;
    squeals = ../users/squeals/home.nix;
  };
};
```

### Option 3: Modify dio/home.nix to not require inputs' (Not recommended)
This would break the dots framework integration.

## Implementation Plan
1. **Option 1**: Update `hosts/shulkerbox.nix` to properly pass `inputs'` to user configs
2. **Option 2**: Alternatively, use specialArgs approach for cleaner solution
3. Test the build to ensure it works
4. Verify all user configs work correctly

## Files to Modify
- `hosts/shulkerbox.nix` - Lines 472-477 (home-manager configuration)

## Testing
Run: `nix build .#nixosConfigurations.shulkerbox.config.system.build.toplevel`