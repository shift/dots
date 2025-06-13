{
  services.comin = {
    enable = true;
    remotes = [
      {
        name = "origin";
        url = "https://github.com/shift/dots.git";
        branches.main.name = "main";
      }
    ];
  };
}
