{
  config,
  mkTrivialModule,
  ...
}:
let
  domain = "prometheus.0jb.de";
  acmeHost = config.networking.fqdn;
  ip = "[::1]";
  localPort = 9089;
in
mkTrivialModule {
  wat.thelegy.acme.extraDomainNames = [ domain ];

  environment.etc."alloy/prometheus-exporter.alloy".text = ''
    prometheus.scrape "prometheus" {
      targets = [{"__address__" = "127.0.0.1:${toString localPort}"}]
      forward_to = [prometheus.remote_write.default.receiver]
    }
  '';

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

  services.nginx.virtualHosts.${domain} = {
    forceSSL = true;
    useACMEHost = acmeHost;
    locations."/" = {
      proxyPass = "http://${ip}:${toString localPort}";
      recommendedProxySettings = true;
      proxyWebsockets = true;
    };
  };
}
