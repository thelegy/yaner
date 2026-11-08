{ wat, ... }:
{
  flake.nixosModules.nginx = wat.mkModuleWrapped [ "nginx" ] (
    {
      cfg,
      config,
      lib,
      ...
    }:
    with lib;

    {
      options = {

        port = mkOption {
          type = types.port;
          default = 17382;
        };

      };
      config =
        let
          port = cfg.port;
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

  );
}
