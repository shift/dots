{
  services.comin = {
    enable = true;
    remotes = [
      {
        name = "origin";
        url = "https://gitlab.com/shift/dots.git";
        branches.main.name = "main";
      }
    ];
  };
}
