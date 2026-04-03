{
  mkModule,
  config,
  lib,
  liftToNamespace,
  ...
}:

mkModule {
  options =
    cfg:
    liftToNamespace {
      domain = lib.mkOption {
        type = lib.types.str;
        default = "actual.beinke.cloud";
      };

      sopsSecretsFile = lib.mkOption {
        type = lib.types.str;
        default = "actual-env";
      };
    };
  config =
    cfg:
    let
      secretsFile = config.sops.secrets.${cfg.sopsSecretsFile}.path;
      hostname = "127.0.0.1";
      port = 57726;
    in
    {

      services.actual = {
        enable = true;
        settings = {
          inherit hostname port;
        };
      };

      systemd.services.actual = {
        serviceConfig.EnvironmentFile = secretsFile;
      };

      sops.secrets.${cfg.sopsSecretsFile} = {
        format = "yaml";
        mode = "0600";
        restartUnits = [ "actual.service" ];
      };

      wat.thelegy.traefik.dynamicConfigs.actual = {
        http.services.actual.loadBalancer = {
          servers = [ { url = "http://${hostname}:${toString port}"; } ];
        };
        http.routers.actual = {
          rule = "Host(`${cfg.domain}`)";
          service = "actual";
        };
      };

    };
}
