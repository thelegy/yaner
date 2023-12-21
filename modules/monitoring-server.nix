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
    };

    wat.thelegy.monitoring.scrapeConfigs.prometheus = {
      static_configs = [
        {
          targets = ["127.0.0.1:${toString localPort}"];
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
