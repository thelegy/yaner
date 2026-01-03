{
  mkModule,
  config,
  lib,
  liftToNamespace,
  ...
}:
with lib;

mkModule {
  options =
    cfg:
    liftToNamespace {

      port = mkOption {
        type = types.port;
        default = 17382;
      };

    };
  config =
    cfg:
    let
      port = config.wat.thelegy.nginx.port;
    in
    {

      services.nginx = {
        enable = true;
        virtualHosts.default = {
          default = true;
          locations."/".return = "404";
        };
        defaultListen = [
          {
            addr = "127.0.0.1";
            inherit port;
            ssl = false;
          }
          {
            addr = "[::1]";
            inherit port;
            ssl = false;
          }
        ];
      };

      wat.thelegy.traefik.dynamicConfigs.nginx = {
        http.services.nginx = {
          loadBalancer.servers = [ { url = "http://localhost:${toString port}"; } ];
        };
      };

    };
}
