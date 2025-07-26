{
  lib,
  pkgs,
  pkgs-unstable ? pkgs,
  ...
}:
{
  # Additional tools and packages
  environment.systemPackages =
    with pkgs;
    [
      (inkscape-with-extensions.override {
        inkscapeExtensions = [
          inkscape-extensions.inkstitch
        ];
      })
      browsh
      SDL_compat
      intel-gpu-tools
      irqbalance
      libcec
      wireplumber
      dracula-theme
      lisgd
      font-awesome
    ]
    ++ lib.optionals (pkgs-unstable != pkgs) (
      with pkgs-unstable;
      [
        pbpctrl
        sops
      ]
    );
}
