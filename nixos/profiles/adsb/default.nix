{ config, pkgs, ... }:

{
  # Set up the RTL-SDR dongle
  services.rtl_sdr = {
    enable = true;
    device = {
      index = 0; # Assuming this is the only SDR device connected
      ppmError = 0; # Set to the known error of your dongle, if known
    };
  };

  # FlightAware software configuration
  services.flightaware = {
    enable = true;
    feederId = "your-feeder-id"; # Replace with your actual feeder ID
  };
}
