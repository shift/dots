{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.grafana-alloy-laptop;

  # Types for scrape configurations
  scrapeConfigType = types.submodule {
    options = {
      job_name = mkOption {
        type = types.str;
        description = "Name of the scrape job";
      };

      targets = mkOption {
        type = types.listOf types.str;
        description = "List of scrape targets in host:port format";
      };

      metrics_path = mkOption {
        type = types.str;
        default = "/metrics";
        description = "HTTP path to scrape metrics from";
      };

      scrape_interval = mkOption {
        type = types.str;
        default = "15s";
        description = "How frequently to scrape the target";
      };

      scrape_timeout = mkOption {
        type = types.str;
        default = "10s";
        description = "Timeout for scrape requests";
      };

      labels = mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = "Additional labels to add to scraped metrics";
      };

      extra_config = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        description = "Additional configuration for the scrape job";
      };
    };
  };

  # Formatted YAML output for a single scrape config
  formatScrapeConfig = cfg: ''
    - job_name: ${cfg.job_name}
      static_configs:
        - targets: ${builtins.toJSON cfg.targets}
          ${optionalString (cfg.labels != { }) "labels:"}
          ${concatStringsSep "\n" (
            mapAttrsToList (name: value: "            ${name}: ${value}") cfg.labels
          )}
      metrics_path: ${cfg.metrics_path}
      scrape_interval: ${cfg.scrape_interval}
      scrape_timeout: ${cfg.scrape_timeout}
      ${concatStringsSep "\n" (
        mapAttrsToList (name: value: "      ${name}: ${builtins.toJSON value}") cfg.extra_config
      )}
  '';

in
{
  options.services.grafana-alloy-laptop = {
    enable = mkEnableOption "Grafana Alloy with built-in node_exporter for laptop metrics";

    scrapeConfigs = mkOption {
      type = types.listOf scrapeConfigType;
      default = [ ];
      description = "Additional scrape configurations to add to Grafana Alloy";
      example = literalExpression ''
        [
          {
            job_name = "my_exporter";
            targets = [ "localhost:9091" ];
            labels = { service = "my-custom-service"; };
          }
        ]
      '';
    };

    grafanaCloud = {
      url = mkOption {
        type = types.str;
        description = "Grafana Cloud Prometheus remote write URL";
        example = "https://prometheus-prod-01-eu-west-0.grafana.net/api/prom/push";
      };

      username = mkOption {
        type = types.str;
        description = "Grafana Cloud username/instance ID";
      };

      password = mkOption {
        type = types.attrs;
        description = "Grafana Cloud API sops-nix secret";
      };
    };

    textfileCollector = {
      enable = mkEnableOption "Node exporter textfile collector";

      directory = mkOption {
        type = types.str;
        default = "/var/lib/grafana-alloy/textfile";
        description = "Directory for node_exporter textfile collector to read metrics from";
      };
    };

    extraNodeExporterArgs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Extra arguments to pass to the embedded node_exporter";
      example = [ "--collector.systemd" ];
    };

    bufferConfig = {
      maxSize = mkOption {
        type = types.int;
        default = 1024;
        description = "Maximum size of disk buffer in MB";
      };

      directory = mkOption {
        type = types.str;
        default = "/var/lib/grafana-alloy/buffer";
        description = "Directory for metrics buffering";
      };
    };
  };

  config = mkIf cfg.enable {
    # Create necessary directories
    systemd.tmpfiles.rules = [
      # Create textfile directory if enabled
      (mkIf cfg.textfileCollector.enable "d ${cfg.textfileCollector.directory} 0755 nobody nobody - -")
      # Create buffer directory
      "d ${cfg.bufferConfig.directory} 0755 nobody nobody - -"
    ];

    # Set up Grafana Alloy service
    systemd.services.grafana-alloy = {
      description = "Grafana Alloy for laptop metrics";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        ExecStart = "${pkgs.grafana-alloy}/bin/alloy run /run/secrets/rendered/grafana-alloy --storage.path=${cfg.bufferConfig.directory}";
        Restart = "always";
        User = "nobody";
        Group = "nobody";
        DynamicUser = true;
        ProtectSystem = "full";
        ProtectHome = true;
        NoNewPrivileges = true;
      };
    };

    # Configure Grafana Alloy
    sops.templates."grafana-alloy/config.yaml".owner = "nobody";
    sops.templates."grafana-alloy/config.yaml".content = ''
      server:
        log_level: info

      metrics:
        global:
          scrape_interval: 15s
          external_labels:
            host: ${config.networking.hostName}
        
        configs:
          - name: integrations
            remote_write:
              - url: ${cfg.grafanaCloud.url}
                basic_auth:
                  username: ${cfg.grafanaCloud.username}
                  password: ${config.sops.placeholder.grafana_api_token}
                queue_config:
                  capacity: 10000
                  max_samples_per_send: 1000
                  batch_send_deadline: 5s
                  min_backoff: 1s
                  max_backoff: 10s
                
                # Configure disk buffering
                wal:
                  enabled: true
                  truncate_frequency: 2h
                  min_keepalive_time: 5m
                  max_keepalive_time: 8h
                  directory: "${cfg.bufferConfig.directory}" 
                  max_size: ${toString (cfg.bufferConfig.maxSize * 1024 * 1024)} # Convert MB to bytes
                  
            # Configure node_exporter
            integrations:
              node_exporter:
                enabled: true
                include_exporter_metrics: true
                
                # Enable battery collector and other useful collectors for laptops
                enable_collectors:
                  - "battery"
                  - "uname"
                  - "meminfo"
                  - "cpu"
                  - "diskstats"
                  - "filesystem"
                  - "loadavg"
                  - "netdev"
                  - "thermal_zone"
                  - "powersupply"  # For power supply information including batteries
                  ${lib.optionalString cfg.textfileCollector.enable ''
                    - "textfile"
                  ''}
                
                # Battery specific configuration
                battery:
                  enable_extended_metrics: true
                
                ${lib.optionalString cfg.textfileCollector.enable ''
                  textfile:
                    directory: "${cfg.textfileCollector.directory}"
                ''}
                
                # Add extra arguments
                extra_args: ${builtins.toJSON cfg.extraNodeExporterArgs}
                
            ${optionalString (cfg.scrapeConfigs != [ ]) ''
              # Additional scrape configurations
              scrape_configs:
                ${concatStringsSep "\n" (map formatScrapeConfig cfg.scrapeConfigs)}
            ''}
    '';

    # Create a systemd timer to periodically collect battery metrics if necessary
    systemd.services.battery-metrics-collector = {
      description = "Collect additional battery metrics";
      script = ''
        #!/bin/sh

        # Count number of batteries
        BATTERY_COUNT=$(ls -1 /sys/class/power_supply/BAT* 2>/dev/null | wc -l || echo 0)

        # Create metrics output directory if it doesn't exist
        mkdir -p ${cfg.textfileCollector.directory}

        # Output battery count as a metric
        echo "# HELP node_battery_count Number of batteries detected in the system" > ${cfg.textfileCollector.directory}/battery_count.prom
        echo "# TYPE node_battery_count gauge" >> ${cfg.textfileCollector.directory}/battery_count.prom
        echo "node_battery_count $BATTERY_COUNT" >> ${cfg.textfileCollector.directory}/battery_count.prom

        # For each battery, get and record additional metrics that node_exporter might not provide
        for i in $(seq 0 $((BATTERY_COUNT-1))); do
          BAT_PATH="/sys/class/power_supply/BAT$i"
          
          if [ -d "$BAT_PATH" ]; then
            # Get battery cycle count if available
            if [ -f "$BAT_PATH/cycle_count" ]; then
              CYCLE_COUNT=$(cat "$BAT_PATH/cycle_count")
              echo "# HELP node_battery_cycle_count Battery charge cycle count" >> ${cfg.textfileCollector.directory}/battery_details.prom
              echo "# TYPE node_battery_cycle_count counter" >> ${cfg.textfileCollector.directory}/battery_details.prom
              echo "node_battery_cycle_count{battery=\"BAT$i\"} $CYCLE_COUNT" >> ${cfg.textfileCollector.directory}/battery_details.prom
            fi
            
            # Get battery health metrics if available
            if [ -f "$BAT_PATH/charge_full" ] && [ -f "$BAT_PATH/charge_full_design" ]; then
              CHARGE_FULL=$(cat "$BAT_PATH/charge_full")
              CHARGE_FULL_DESIGN=$(cat "$BAT_PATH/charge_full_design")
              
              # Calculate health percentage
              if [ "$CHARGE_FULL_DESIGN" -gt 0 ]; then
                HEALTH_PCT=$(awk "BEGIN {printf \"%.2f\", ($CHARGE_FULL / $CHARGE_FULL_DESIGN) * 100}")
                echo "# HELP node_battery_health_percent Battery health percentage (current full capacity divided by design capacity)" >> ${cfg.textfileCollector.directory}/battery_details.prom
                echo "# TYPE node_battery_health_percent gauge" >> ${cfg.textfileCollector.directory}/battery_details.prom
                echo "node_battery_health_percent{battery=\"BAT$i\"} $HEALTH_PCT" >> ${cfg.textfileCollector.directory}/battery_details.prom
              fi
            fi
          fi
        done

        # Fix permissions
        chmod 644 ${cfg.textfileCollector.directory}/*.prom
      '';
      serviceConfig = {
        Type = "oneshot";
        User = "nobody";
        Group = "nobody";
      };
    };

    systemd.timers.battery-metrics-collector = mkIf cfg.textfileCollector.enable {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "1m";
        OnUnitActiveSec = "5m";
      };
    };
  };
}
