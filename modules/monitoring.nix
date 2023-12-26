{
  config,
  lib,
  liftToNamespace,
  mkModule,
  pkgs,
  ...
}:
with lib; let
  yaml = pkgs.formats.yaml {};
in
  mkModule {
    options = cfg:
      liftToNamespace {
        remoteWriteUrl = mkOption {
          type = types.str;
          default = "https://prometheus.0jb.de:9090/api/v1/write";
        };
        lokiUrl = mkOption {
          type = types.nullOr types.str;
          default = "https://loki.0jb.de:3100/loki/api/v1/push";
        };
        scrapeConfigs = mkOption {
          type = types.attrsOf yaml.type;
          default = {};
        };
      };

    config = cfg: {
      services.grafana-agent = {
        enable = true;
        extraFlags = ["-disable-reporting" "-disable-support-bundle"];
        settings = {
          metrics = {
            wal_directory = "\${STATE_DIRECTORY}/metrics-wal";
            global.remote_write = [{url = cfg.remoteWriteUrl;}];
            configs = [
              {
                name = "default";
                scrape_configs = mapAttrsToList (k: v:
                  v
                  // {
                    job_name = k;
                    static_configs =
                      map (
                        c:
                          recursiveUpdate {
                            labels.instance = config.networking.hostName;
                          }
                          c
                      )
                      v.static_configs or [];
                  })
                cfg.scrapeConfigs;
              }
            ];
          };
          integrations = {
            agent = {
              # enabled = true;
              # scrape_integration = true;
              instance = config.networking.hostName;
            };

            node_exporter = {
              # enabled = true;
              # scrape_integration = true;
              instance = config.networking.hostName;
              enable_collectors = ["systemd"];
            };
          };
          logs = mkIf (! isNull cfg.lokiUrl) {
            positions_directory = "\${STATE_DIRECTORY}/logs-positions";
            configs = [
              {
                name = "journal";
                clients = [{url = cfg.lokiUrl;}];
                scrape_configs = [
                  {
                    job_name = "journal";
                    journal = {
                      max_age = "12h";
                      labels = {
                        job = "journal";
                        host = config.networking.hostName;
                      };
                    };
                    relabel_configs = let
                      label = target: source: {
                        source_labels = ["__journal_${source}"];
                        target_label = target;
                      };
                    in [
                      (label "cmdLine" "_cmdline")
                      (label "pid" "_pid")
                      (label "priority" "priority")
                      (label "slice" "_systemd_slice")
                      (label "syslogFacility" "syslog_facility")
                      (label "syslogIdentifier" "syslog_identifier")
                      (label "uid" "_uid")
                      (label "unit" "_systemd_unit")
                    ];
                  }
                ];
              }
            ];
          };
        };
      };
    };
  }
