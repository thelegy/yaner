{
  config,
  mkTrivialModule,
  ...
}:

mkTrivialModule {
  services.prometheus.exporters.smartctl = {
    enable = true;
    listenAddress = "127.0.0.1";
  };

  environment.etc."alloy/smartctl-exporter.alloy".text = let
    inherit (config.services.prometheus.exporters.smartctl) listenAddress port;
  in ''
    prometheus.scrape "smartctl" {
      targets = [
        {"__address__" = "${listenAddress}:${toString port}"},
      ]
      scrape_interval = "2m"
      forward_to = [prometheus.relabel.default.receiver]
    }
  '';
}
