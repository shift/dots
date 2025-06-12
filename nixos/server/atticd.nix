{ flake, ... }:
{

  services.atticd = {
    enable = true;

    # Replace with absolute path to your credentials file
    credentialsFile = "/etc/atticd.env";

    settings = {
      listen = "[::]:8080";

      chunking = {
        nar-size-threshold = 64 * 1024; # 64 KiB
        min-size = 16 * 1024; # 16 KiB
        avg-size = 64 * 1024; # 64 KiB
        max-size = 256 * 1024; # 256 KiB
      };
      garbage-collection = {
        interval = "12 hours";
        default-retention-period = "4 weeks";
      };
      compression = {
        type = "zstd";
        level = 9;
      };
      storage = {
        type = "s3";
        region = "eu-central-1";
        bucket = "nix-store";
        endpoint = "http://localhost:9000/";
      };
    };
  };
}
