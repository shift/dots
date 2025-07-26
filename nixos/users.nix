{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Common user groups for desktop users
  commonUserGroups = [
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
in
{
  # User management configuration
  users.mutableUsers = false;
  users.defaultUserShell = pkgs.zsh;
  programs.zsh.enable = true;

  # Additional user groups
  users.groups = {
    children = {
      name = "children";
    };
  };

  # Create users based on SOPS secrets
  users.users.shift = lib.mkIf (config.sops.secrets ? "shift_hashed_passwd") {
    hashedPasswordFile = config.sops.secrets."shift_hashed_passwd".path;
    isNormalUser = true;
    extraGroups = commonUserGroups;
    shell = "${pkgs.zsh}/bin/zsh";
  };

  users.users.dio = lib.mkIf (config.sops.secrets ? "dio_hashed_passwd") {
    hashedPasswordFile = config.sops.secrets."dio_hashed_passwd".path;
    isNormalUser = true;
    extraGroups = commonUserGroups ++ [ "children" ];
  };

  users.users.squeals = lib.mkIf (config.sops.secrets ? "squeals_hashed_passwd") {
    hashedPasswordFile = config.sops.secrets."squeals_hashed_passwd".path;
    isNormalUser = true;
    extraGroups = commonUserGroups ++ [ "children" ];
  };

  # Development tools
  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = false;
  programs.adb.enable = true;
  programs.tmux.enable = true;

  # USB device rules for development
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="1949", ATTR{idProduct}=="0588", MODE="0666", GROUP="adbusers"
    SUBSYSTEM=="usb", ATTR{idVendor}=="1949", ATTR{idProduct}=="0282", MODE="0666", GROUP="adbusers"
  '';
}
