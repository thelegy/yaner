{
  config,
  mkTrivialModule,
  ...
}:

mkTrivialModule {
  services.prometheus.exporters.smartctl.enable = true;

  environment.etc."alloy/smartctl-exporter.alloy".text = ''
    prometheus.scrape "smartctl" {
      targets = [
        {"__address__" = "localhost:${toString config.services.prometheus.exporters.smartctl.port}"},
      ]
      scrape_interval = "2m"
      forward_to = [prometheus.remote_write.default.receiver]
    }
  '';
}
