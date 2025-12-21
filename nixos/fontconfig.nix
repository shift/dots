{ pkgs, ... }:
{
  fonts = {
    enableDefaultPackages = false;

    fontconfig = {
      enable = true;

      antialias = true;

      defaultFonts = {
        emoji = [ "Noto Color Emoji" ];
        monospace = [
          "Fira Code"
          "Noto Color Emoji"
          "Symbols Nerd Font"
        ];
        serif = [
          "Noto Serif"
          "Noto Color Emoji"
        ];
        sansSerif = [
          "Inter"
          "Noto Color Emoji"
        ];
      };

      hinting = {
        enable = true;
        autohint = false;
        style = "full";
      };

      subpixel = {
        lcdfilter = "default";
        rgba = "rgb";
      };
    };

    fontDir = {
      enable = true;
      decompressFonts = true;
    };

    packages = with pkgs; [
      fira-code
      fira-code-symbols
      material-design-icons
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      roboto-mono
      font-awesome

      (google-fonts.override { fonts = [ "Inter" ]; })
      nerd-fonts.symbols-only
      #(nerdif``onts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
    ];
  };

  stylix.fonts = {
    serif = {
      package = pkgs.nerd-fonts.fira-code;
      name = "Fira Code Nerd Font";
    };

    sansSerif = {
      package = pkgs.nerd-fonts.fira-code;
      name = "Fira Code Nerd Font";
    };

    monospace = {
      package = pkgs.nerd-fonts.fira-code;
      name = "Fira Code Nerd Font";
    };

    emoji = {
      package = pkgs.noto-fonts-color-emoji;
      name = "Noto Color Emoji";
    };
  };
}
