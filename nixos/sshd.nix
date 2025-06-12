{
  services.openssh.enable = true;
  services.openssh.settings.DenyGroups = [ "children" ];
}
