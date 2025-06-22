# Hosts directory entry point
# This file dynamically discovers and imports all host directories
{ lib, ... }:

let
  # Get all directories in the current directory (hosts/)
  hostDirs = builtins.readDir ./.;
  
  # Filter to only include directories (not files like this default.nix)
  onlyDirs = lib.filterAttrs (name: type: type == "directory") hostDirs;
  
  # Create import paths for each host directory
  hostImports = lib.mapAttrsToList (name: _: ./${name}) onlyDirs;
in
{
  # Export the hosts for use by flake.nix
  # This allows the flake to access individual host configurations
  hosts = onlyDirs;
  
  # For backward compatibility, we don't import anything here
  # The flake.nix will import the specific host configurations directly
}