{
  mkTrivialModule,
  config,
  pkgs,
  ...
}:

let
  hostName = "spoolman.0jb.de";
  acmeHost = config.networking.fqdn;
  port = 7020;
  bin = pkgs.spoolman;
in
mkTrivialModule {

  systemd.services.spoolman = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${bin}/bin/spoolman --port ${toString port}";
      DynamicUser = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateDevices = true;
      ProtectControlGroups = true;
      ProtectKernelLogs = true;
      StateDirectory = "spoolman";
      Environment = "SPOOLMAN_DIR_DATA=/var/lib/spoolman";
    };
  };

  services.nginx.virtualHosts.${hostName} = {
    forceSSL = true;
    useACMEHost = acmeHost;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString port}";
      recommendedProxySettings = true;
      proxyWebsockets = true;
    };
  };

}
