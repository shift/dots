{
  pkgs,
  ...
}:

let
  theme = "${pkgs.base16-schemes}/share/themes/catppuccin-frappe.yaml";
in
{
  stylix = {
    base16Scheme = theme;
    cursor = {
      name = "Catppuccin-Frappe-Dark-Cursors";
      size = 26;
      package = pkgs.catppuccin-cursors.frappeDark;
    };
  };
}
