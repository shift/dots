{ pkgs, ... }:
let
  hibernateEnvironment = {
    # Set the timeout to 1 hour
    HIBERNATE_SECONDS = "3600";
    HIBERNATE_LOCK = "/run/autohibernate.lock"; # Use /run, it's tmpfs
  };
in
{
  # Ensures the lock file directory exists
  systemd.tmpfiles.rules = [
    "d ${hibernateEnvironment.HIBERNATE_LOCK} 0755 root root -"
  ];

  systemd.services."suspend-then-hibernate-prepare" = {
    description = "Set RTC wake alarm to trigger hibernation";
    wantedBy = [ "suspend.target" ];
    # Run before the system actually suspends
    before = [ "systemd-suspend.service" ];
    environment = hibernateEnvironment;
    script = ''
      # Write a timestamp to the lock file and set the RTC alarm
      echo "$(date +%s)" > $HIBERNATE_LOCK
      ${pkgs.util-linux}/bin/rtcwake -m no -s $HIBERNATE_SECONDS
    '';
    serviceConfig.Type = "oneshot";
  };

  systemd.services."suspend-then-hibernate-resume" = {
    description = "Hibernate or cancel alarm on resume";
    wantedBy = [ "suspend.target" ];
    # Run after the system has resumed
    after = [ "systemd-suspend.service" ];
    environment = hibernateEnvironment;
    script = ''
      # Exit if the lock file doesn't exist
      if [ ! -f $HIBERNATE_LOCK ]; then
        exit 0
      fi

      curtime=$(date +%s)
      sustime=$(cat $HIBERNATE_LOCK)

      # Clean up the lock file immediately
      rm $HIBERNATE_LOCK

      # Check if the elapsed time is greater than or equal to our hibernate timer
      if [ $(($curtime - $sustime)) -ge $HIBERNATE_SECONDS ] ; then
        # If yes, we woke up from the timer, so hibernate
        systemctl hibernate
      else
        # If no, we woke up manually. CRITICAL: Cancel the pending RTC alarm.
        ${pkgs.util-linux}/bin/rtcwake -m no -s 0
      fi
    '';
    serviceConfig.Type = "oneshot";
  };
}
