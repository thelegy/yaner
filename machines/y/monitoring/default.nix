{
  config,
  ...
}:
let
  local_ip = "127.0.0.60";
  local_port = 3000;
  domain = "grafana.0jb.de";
in
{
  services.grafana = {
    enable = true;
    settings = {
      server = {
        domain = domain;
        root_url = "https://${domain}/";
        http_addr = local_ip;
        http_port = local_port;
      };
      database = {
        wal = true;
      };
    };
    provision.enable = true;
    provision.datasources.settings.datasources = [
      {
        name = "prometheus";
        type = "prometheus";
        url = "https://prometheus.0jb.de/";
      }
    ];
    provision.dashboards.settings.providers = [
      {
        name = "yaner dashboards";
        options.path = ./dashboards;
        options.foldersFromFilesStructure = true;
        # Nix store is constant so no update is ever needed
        updateIntervalSeconds = 999999999;
      }
    ];
  };

  environment.etc."alloy/grafana-exporter.alloy".text = ''
    prometheus.scrape "grafana" {
      targets = [{"__address__" = "${local_ip}:${toString local_port}"}]
      forward_to = [prometheus.remote_write.default.receiver]
    }
  '';

  services.nginx.virtualHosts.${domain} = {
    forceSSL = true;
    useACMEHost = config.networking.fqdn;
    locations."/" = {
      proxyPass = "http://${local_ip}:${toString local_port}/";
      recommendedProxySettings = true;
      proxyWebsockets = true;
    };
  };
}
