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
        };
      };
    };
  }
