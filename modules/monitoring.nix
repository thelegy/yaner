{ lib
, pkgs
, mkTrivialModule
, ...}: with lib;

mkTrivialModule {

  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [
      "systemd"
    ];
  };

  services.nginx.virtualHosts.main = {
    locations."/<redacted>" = {
      proxyPass = "<redacted>";
    };
  };

}
