{ config, lib, ... }:

with lib;

let
  cfg = config.security.sharedSudoAuth;
in
{
  options.security.sharedSudoAuth = {
    enable = mkEnableOption "shared sudo authentication across terminals";

    timestampType = mkOption {
      type = types.enum [
        "global"
        "ppid"
        "tty"
      ];
      default = "global";
      description = ''
        Controls how sudo determines if an authentication timestamp is still valid.

        - global: The timestamp is shared between all terminals
        - ppid: The timestamp is shared among processes with the same parent
        - tty: The timestamp is restricted to the same terminal (default sudo behavior)
      '';
    };

    timestampTimeout = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = ''
        Number of minutes before sudo authentication expires.
        If null, the default timeout will be used (usually 15 minutes).
      '';
      example = 30;
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Additional sudo configuration to be appended.";
    };
  };

  config = mkIf cfg.enable {
    security.sudo = {
      enable = true;

      extraConfig = ''
        # Make sudo authentication timeout shared according to configuration
        Defaults timestamp_type=${cfg.timestampType}

        ${optionalString (
          cfg.timestampTimeout != null
        ) "Defaults timestamp_timeout=${toString cfg.timestampTimeout}"}

        ${cfg.extraConfig}
      '';
    };

  };
}
