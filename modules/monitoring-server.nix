{
  config,
  mkTrivialModule,
  ...
}:
let
  domain = "prometheus.0jb.de";
  ip = "[::1]";
  localPort = 9089;
in
mkTrivialModule {
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

  wat.thelegy.traefik.dynamicConfigs.monitoring = {
    http.services.prometheus.loadBalancer = {
      servers = [ { url = "http://${ip}:${toString localPort}"; } ];
    };
    http.routers.prometheus = {
      rule = "Host(`${domain}`)";
      service = "prometheus";
    };
  };
}
