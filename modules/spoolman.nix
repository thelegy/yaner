{
  mkTrivialModule,
  pkgs,
  ...
}:

let
  hostName = "spoolman.0jb.de";
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

  wat.thelegy.traefik.dynamicConfigs.spoolman = {
    http.services.spoolman.loadBalancer = {
      servers = [ { url = "http://127.0.0.1:${toString port}"; } ];
    };
    http.routers.spoolman = {
      rule = "Host(`${hostName}`)";
      service = "spoolman";
    };
  };

}
