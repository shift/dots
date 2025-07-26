{
  lib,
  pkgs,
  ...
}:
{
  # Sway window manager with Wayland configuration
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

  # XDG portals for Wayland
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gtk
    ];
  };

  # Wayland environment variables
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.sessionVariables.WLR_RENDERER = "vulkan";
  environment.sessionVariables.ELECTRON_OZONE_PLATFORM_HINT = "wayland";

  # Required packages for Sway
  environment.systemPackages = with pkgs; [
    qt5.qtwayland
    glfw-wayland
    cage
    sway
  ];

  # Display manager configuration
  services.greetd = {
    enable = true;
    settings.background.fit = "Fill";
  };

  programs.regreet = {
    enable = true;
    settings = {
    };
  };

  # X11 keymap (affects TTY as well)
  services.xserver = {
    xkb = {
      layout = lib.mkForce "us";
      options = "eurosign:e,ctrl:nocaps,ctrl:swapcaps";
    };
  };

  services.libinput.enable = true;

  # Fallback desktop environment
  services.xserver.desktopManager.cinnamon.enable = lib.mkDefault false;

  # Cursor theme
  stylix.cursor.package = lib.mkDefault pkgs.bibata-cursors;
  stylix.cursor.name = lib.mkDefault "Bibata-Modern-Ice";
  stylix.cursor = {
    size = lib.mkDefault 26;
  };
}
