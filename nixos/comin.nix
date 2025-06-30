{
  services.comin = {
    enable = true;
    exporter.listen_address = "127.0.0.1";
    remotes = [
      {
        name = "origin";
        url = "https://github.com/shift/dots.git";
        branches.main.name = "main";
      }
    ];
  };
}
