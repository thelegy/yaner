{
  config,
  mkTrivialModule,
  ...
}:
mkTrivialModule {
  services.prometheus.exporters.smartctl.enable = true;

  wat.thelegy.monitoring.scrapeConfigs.smartctl = {
    scrape_interval = "2m";
    static_configs = [
      {
        targets = ["localhost:${toString config.services.prometheus.exporters.smartctl.port}"];
      }
    ];
  };
}
