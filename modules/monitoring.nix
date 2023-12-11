{
  config,
  lib,
  liftToNamespace,
  mkModule,
  pkgs,
  ...
}:
with lib; let
  yaml = pkgs.formats.json {};
  user = "grafana-agent";
  group = user;
in
  mkModule {
    options = cfg:
      liftToNamespace {
        remoteWriteUrl = mkOption {
          type = types.str;
          default = "https://prometheus.0jb.de:9090/api/v1/write";
        };
        settings = mkOption {
          type = yaml.type;
        };
        scrapeConfigs = mkOption {
          type = types.listOf yaml.type;
        };
      };

    config = cfg: let
      configFile = yaml.generate "grafana-agent.yaml" cfg.settings;
    in
      (liftToNamespace {
        settings = {
          metrics = {
            wal_directory = "\${STATE_DIRECTORY}";

            global.remote_write = [{url = cfg.remoteWriteUrl;}];

            configs = [
              {
                name = "default";
                scrape_configs = cfg.scrapeConfigs;
              }
            ];
          };
          integrations = {
            agent = {
              enabled = true;
              scrape_integration = true;
              instance = config.networking.hostName;
            };

            node_exporter = {
              enabled = true;
              scrape_integration = true;
              instance = config.networking.hostName;
              enable_collectors = ["systemd"];
            };
          };
        };

        scrapeConfigs = [];
      })
      // {
        systemd.services.grafana-agent = {
          wantedBy = ["multi-user.target"];
          serviceConfig = {
            ExecStart = "${pkgs.grafana-agent}/bin/grafana-agent -disable-reporting -config.expand-env -config.file ${configFile}";
            Type = "exec";
            Restart = "always";
            RestartSec = 10;
            StateDirectory = "grafana-agent";

            # DynamicUser currently breaks connection to the system dbus which is needed for the node_exporter
            #DynamicUser = true;
            User = user;
            Group = group;
            ProtectSystem = "strict";
            ProtectHome = "tmpfs";
            RemoveIPC = true;
            PrivateTmp = true;
            NoNewPrivileges = true;
            RestrictSUIDSGID = true;
          };
        };
        users.groups.${group} = {};
        users.users.${user} = {
          isSystemUser = true;
          group = group;
        };
      };
  }
