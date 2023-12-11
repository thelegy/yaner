{
  config,
  lib,
  mkTrivialModule,
  pkgs,
  ...
}:
with lib; let
  domain = "prometheus.0jb.de";
  acmeHost = config.networking.fqdn;
  ip = "[::1]";
  localPort = 9089;
  remotePort = 9090;
in
  mkTrivialModule {
    wat.thelegy.acme.extraDomainNames = [domain];

    wat.thelegy.monitoring = {
      enable = true;
      scrapeConfigs = [
        {
          job_name = "prometheus";
          static_configs = [
            {
              targets = ["127.0.0.1:${toString localPort}"];
              labels.instance = config.networking.hostName;
            }
          ];
        }
      ];
    };

    services.prometheus = {
      enable = true;
      stateDir = "prometheus";
      listenAddress = ip;
      port = localPort;
      extraFlags = [
        "--storage.tsdb.retention.size=32GB"
        "--web.enable-remote-write-receiver"
        "--web.enable-admin-api"
      ];
      scrapeConfigs = [
        {
          job_name = "mirror_agony";
          scrape_interval = "15s";
          # honor_labels = true;
          metrics_path = "/federate";
          params."match[]" = [
            ''{instance=~"agony.0jb.de:.*"}''
          ];
          static_configs = [
            {
              targets = ["roborock.0jb.de:9090"];
              labels.instance = "agony";
            }
          ];
          relabel_configs = [
            {
              source_labels = ["exported_job"];
              target_label = "job";
              regex = "(.*)";
              replacement = "\${1}";
            }
          ];
        }
        {
          job_name = "mirror_roborock";
          scrape_interval = "15s";
          # honor_labels = true;
          metrics_path = "/federate";
          params."match[]" = [
            ''{instance=~"roborock.0jb.de:.*"}''
          ];
          static_configs = [
            {
              targets = ["roborock.0jb.de:9090"];
              labels.instance = "roborock";
            }
          ];
          relabel_configs = [
            {
              source_labels = ["exported_job"];
              target_label = "job";
              regex = "(.*)";
              replacement = "\${1}";
            }
          ];
        }
      ];
    };

    services.nginx.virtualHosts.${domain} = {
      listen = [
        {
          addr = "[::]";
          port = remotePort;
          ssl = true;
        }
      ];
      forceSSL = true;
      useACMEHost = acmeHost;
      locations."/" = {
        proxyPass = "http://${ip}:${toString localPort}";
        recommendedProxySettings = true;
        proxyWebsockets = true;
      };
    };

    networking.nftables.firewall.rules.prometheus = {
      from = ["tailscale"];
      to = ["fw"];
      allowedTCPPorts = [remotePort];
    };
  }
