{ pkgs, ... }:
{
  home.packages = [
    pkgs.git-lfs
    pkgs.pinentry-gnome3
  ];

  programs.ssh = {
    enable = true;
    extraConfig = ''
      AddKeysToAgent yes
    '';
  };

  programs.gpg = {
    enable = true;
    settings = {
      use-agent = true;
    };
  };

  services.gpg-agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-gnome3;
    enableSshSupport = true;
  };

  programs.git = {
    package = pkgs.gitAndTools.gitFull;
    enable = true;
    lfs.enable = true;
    userName = "Vincent Palmer";
    userEmail = "shift@someone.section.me";
    aliases = {
      co = "checkout";
      ci = "commit";
      cia = "commit --amend";
      s = "status";
      st = "status";
      b = "branch";
      pu = "push";
    };
    ignores = [
      "*~"
      "*.swp"
    ];
    delta = {
      enable = true;
      options = {
        features = "decorations";
        navigate = true;
        light = false;
        side-by-side = true;
      };
    };
    extraConfig = {
      init.defaultBranch = "main";
      core.editor = "nvim";
      credential.helper = "store --file ~/.git-credentials";
      pull.rebase = "false";
      # For supercede
      core.symlinks = true;
    };
  };

  programs.lazygit = {
    enable = true;
  };
}
