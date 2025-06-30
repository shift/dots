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
    environment.etc."grafana-alloy/config.alloy" = {
      source = config.sops.templates."grafana-alloy/config.alloy".path;
      user = "nobody";
    };

    # Set up Grafana Alloy service
    systemd.services.grafana-alloy = {
      description = "Grafana Alloy for laptop metrics";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        ExecStart = "${pkgs.grafana-alloy}/bin/alloy run /etc/grafana-alloy --storage.path=${cfg.bufferConfig.directory}";
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
    sops.templates."grafana-alloy/config.alloy".owner = "nobody";
    sops.templates."grafana-alloy/config.alloy".content = ''
     prometheus.exporter.self "alloy_check" { }

             discovery.relabel "alloy_check" {
      	 targets = prometheus.exporter.self.alloy_check.targets

      	 rule {
      	   target_label = "instance"
      	   replacement  = constants.hostname
      	 }

      	 rule {
      	   target_label = "alloy_hostname"
      	   replacement  = constants.hostname
      	 }

      	 rule {
      	   target_label = "job"
      	   replacement  = "integrations/alloy-check"
      	 }
             }

             prometheus.scrape "alloy_check" {
      	 targets    = discovery.relabel.alloy_check.output
      	 forward_to = [prometheus.relabel.alloy_check.receiver]

      	 scrape_interval = "60s"
             }

             prometheus.relabel "alloy_check" {
      	 forward_to = [prometheus.remote_write.metrics_service.receiver]

      	 rule {
      	   source_labels = ["__name__"]
      	   regex         = "(prometheus_target_sync_length_seconds_sum|prometheus_target_scrapes_.*|prometheus_target_interval.*|prometheus_sd_discovered_targets|alloy_build.*|prometheus_remote_write_wal_samples_appended_total|process_start_time_seconds)"
      	   action        = "keep"
      	 }
             }

             prometheus.remote_write "metrics_service" {
      	 endpoint {
      	   url = "${cfg.grafanaCloud.url}"

      	   basic_auth {
      	     username = ${cfg.grafanaCloud.username}
      	     password = "${config.sops.placeholder.grafana_api_token}"
      	   }
      	 }
             }

             loki.source.journal "journal" {
      	  forward_to    = [loki.write.grafana_cloud_loki.receiver]
             }
             loki.write "grafana_cloud_loki" {
      	 endpoint {
      	   url = "${cfg.grafanaCloud.url}"

      	   basic_auth {
      	     username = ${cfg.grafanaCloud.username}
      	     password = "${config.sops.placeholder.grafana_api_token}"
      	   }
      	 }
             }
      	   discovery.relabel "integrations_node_exporter" {
      	     targets = prometheus.exporter.unix.integrations_node_exporter.targets

      	     rule {
      	       target_label = "job"
      	       replacement = "integrations/node_exporter"
      	     }
      	   }

      	   prometheus.exporter.unix "integrations_node_exporter" {
      	     disable_collectors = ["ipvs", "infiniband", "xfs", "zfs", "nfs", "nfsd", "tapestats"]
      	      enable_collectors = ["logind", "network_route", "systemd", "wifi"]

      	     filesystem {
      	       fs_types_exclude     = "^(autofs|binfmt_misc|bpf|cgroup2?|configfs|debugfs|devpts|devtmpfs|tmpfs|fusectl|hugetlbfs|iso9660|mqueue|nsfs|overlay|proc|procfs|pstore|rpc_pipefs|securityfs|selinuxfs|squashfs|sysfs|tracefs)$"
      	       mount_points_exclude = "^/(dev|proc|run/credentials/.+|sys|var/lib/docker/.+)($|/)"
      	       mount_timeout        = "5s"
      	     }

      	     netclass {
      	       ignored_devices = "^(veth.*|cali.*|[a-f0-9]{15})$"
      	     }

      	     netdev {
      	       device_exclude = "^(veth.*|cali.*|[a-f0-9]{15})$"
      	     }
      	   }

      	   prometheus.scrape "integrations_node_exporter" {
      	     targets    = discovery.relabel.integrations_node_exporter.output
      	     forward_to = [prometheus.relabel.integrations_node_exporter.receiver]
      	   }

      	   prometheus.scrape "geoclue" {

      	   targets = [
      	     {__address__ = "127.0.0.1:9090", group = "infrastructure", service = "geoclue"},
      	     {__address__ = "127.0.0.1:4243", group = "infrastructure", service = "comin"},
      	   ]

      	     scrape_interval = "300s"
      	     job_name = ""
      	     forward_to = [prometheus.relabel.integrations_node_exporter.receiver]
      	   }

      	   prometheus.relabel "integrations_node_exporter" {
      	     forward_to = [prometheus.remote_write.metrics_service.receiver]

      	   }
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
