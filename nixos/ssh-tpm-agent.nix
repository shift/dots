{
  pkgs,
  config,
  ...
}:
let
  askPasswordWrapper = pkgs.writeScript "ssh-askpass-wrapper" ''
    #! ${pkgs.runtimeShell} -e
    export DISPLAY="$(systemctl --user show-environment | sed 's/^DISPLAY=\(.*\)/\1/; t; d')"
    export XAUTHORITY="$(systemctl --user show-environment | sed 's/^XAUTHORITY=\(.*\)/\1/; t; d')"
    export WAYLAND_DISPLAY="$(systemctl --user show-environment | sed 's/^WAYLAND_DISPLAY=\(.*\)/\1/; t; d')"
    exec ${config.programs.ssh.askPassword} "$@"
  '';
in
{
  systemd.user.services.ssh-tpm-agent = {
    path = [ pkgs.gnused ];
    description = "SSH Agent";
    wantedBy = [ "default.target" ];
    unitConfig = {
      ConditionUser = "!@system";
      ConditionEnvironment = "!SSH_AGENT_PID";
    };
    environment = {
      SSH_ASKPASS = askPasswordWrapper;
      SSH_AUTH_SOCK = "%t/ssh-tpm-agent.sock";
    };
    serviceConfig = {
      ExecStartPre = "${pkgs.coreutils}/bin/rm -f %t/ssh-agent";
      ExecStart = "${pkgs.ssh-tpm-agent}/bin/ssh-tpm-agent";
      PassEnvironment = "SSH_AGENT_PID";
      SuccessExitStatus = 2;
      Type = "simple";
    };
  };

  systemd.user.sockets.ssh-tpm-agent = {
    wantedBy = [ "sockets.target" ];
    unitConfig.Description = "SSH Agent Socket";
    socketConfig = {
      ListenStream = "%t/ssh-tpm-agent.sock";
      SocketMode = "0600";
      Service = "ssh-tpm-agent.service";
    };
  };

  systemd.user.services.ssh-fido-agent = {
    path = [ pkgs.gnused ];
    description = "SSH Agent";
    wantedBy = [ "default.target" ];
    unitConfig = {
      ConditionUser = "!@system";
      ConditionEnvironment = "!SSH_AGENT_PID";
    };
    environment = {
      SSH_ASKPASS = askPasswordWrapper;
      SSH_AUTH_SOCK = "%t/ssh-fido-agent.sock";
    };
    serviceConfig = {
      ExecStartPre = "${pkgs.coreutils}/bin/rm -f %t/ssh-agent";
      ExecStart = "${pkgs.openssh}/bin/ssh-agent";
      PassEnvironment = "SSH_AGENT_PID";
      SuccessExitStatus = 2;
      Type = "simple";
    };
  };

  systemd.user.sockets.ssh-fido-agent = {
    wantedBy = [ "sockets.target" ];
    unitConfig.Description = "SSH Agent Socket";
    socketConfig = {
      ListenStream = "%t/ssh-fido-agent.sock";
      SocketMode = "0600";
      Service = "ssh-fido-agent.service";
    };
  };
}
