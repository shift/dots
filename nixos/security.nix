{
  lib,
  pkgs,
  ...
}:
{
  # Security configuration for desktop systems

  # TPM2 support
  security = {
    tpm2 = {
      enable = true;
      pkcs11.enable = true;
      tctiEnvironment.enable = true;
    };

    polkit.enable = true;
    rtkit.enable = true;

    pam = {
      loginLimits = [
        {
          domain = "@users";
          item = "rtprio";
          type = "-";
          value = 1;
        }
      ];

      yubico = {
        enable = lib.mkDefault false; # Enable in host-specific config if needed
        debug = false;
        mode = "challenge-response";
      };
    };
  };

  # Yubikey support
  services.udev.packages = [ pkgs.yubikey-personalization ];

  # Polkit configuration for wheel group
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
        if (subject.isInGroup("wheel")) {
          return polkit.Result.YES;
        } else {
          return polkit.Result.NO;
        }
    });
  '';

  # Security-related packages
  environment.systemPackages = with pkgs; [
    ccid
    acsccid
    pcscliteWithPolkit
    pcsc-tools
    yubikey-personalization
    yubico-pam
    cryptsetup
    ssh-tpm-agent
    keyutils
    pinentry-qt
    sbctl
  ];

  # GPG agent configuration
  programs = {
    ssh.startAgent = lib.mkForce false;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage = pkgs.pinentry-qt;
    };
  };
}
