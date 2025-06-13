_: {
  stylix = {
    enable = true;
    autoEnable = true;
    image = ./wallpaper/default.jpg;
    targets = {
      gtk = {
        enable = true;
      };
      waybar = {
        enable = true;
        enableLeftBackColors = true;
        enableRightBackColors = true;
        enableCenterBackColors = true;
      };
      sway = {
        enable = true;
      };
      nixvim = {
        enable = true;
        transparent_bg = {
          sign_column = true;
          main = true;
        };
      };
    };
    opacity = {
      applications = 0.9;
      desktop = 0.8;
      popups = 1.0;
      terminal = 0.7;
    };
  };
}
