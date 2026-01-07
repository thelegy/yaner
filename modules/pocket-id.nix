{
  mkModule,
  lib,
  liftToNamespace,
  config,
  ...
}:
with lib;
mkModule {
  options =
    cfg:
    liftToNamespace {
      domain = mkOption {
        type = types.str;
        default = "auth.beinke.cloud";
      };

      sopsSecretsFile = mkOption {
        type = types.str;
        default = "pocket-id-env";
      };
    };

  config =
    cfg:
    let
      secretsFile = config.sops.secrets.${cfg.sopsSecretsFile}.path;
      host = "127.0.0.1";
      port = 47311;
      prometheus_port = 26959;
    in
    {

      sops.secrets.${cfg.sopsSecretsFile} = {
        format = "yaml";
        mode = "0600";
        restartUnits = [ "pocket-id.service" ];
      };

      services.pocket-id = {
        enable = true;
        environmentFile = secretsFile;
        settings = {
          APP_URL = "https://${cfg.domain}";
          HOST = host;
          PORT = port;
          TRUST_PROXY = true;

          METRICS_ENABLED = true;
          OTEL_EXPORTER_PROMETHEUS_HOST = host;
          OTEL_EXPORTER_PROMETHEUS_port = prometheus_port;
        };
      };

      wat.thelegy.traefik.dynamicConfigs.pocket-id = {
        http.services.pocket-id.loadBalancer = {
          servers = [ { url = "http://${host}:${toString port}"; } ];
        };
        http.routers.pocket-id = {
          rule = "Host(`${cfg.domain}`)";
          service = "pocket-id";
        };
      };

      environment.etc."alloy/pocket-id-exporter.alloy".text = ''
        prometheus.scrape "pocketId" {
          targets = [{"__address__" = "${host}:${toString prometheus_port}"}]
          forward_to = [prometheus.relabel.default.receiver]
        }
      '';
    };
}
