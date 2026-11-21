{ wat, ... }:
{
  flake.nixosModules.mealie = wat.mkModule [ "mealie" ] (
    {
      cfg,
      lib,
      config,
      ...
    }:
    {
      namespaceOptions = {
        oidc.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable Pocket ID authentication";
        };
        oidc.configurationUrl = lib.mkOption {
          type = lib.types.str;
          default = "https://auth.beinke.cloud/.well-known/openid-configuration";
        };
        sopsSecretsFile = lib.mkOption {
          type = lib.types.str;
          default = "mealie-env";
          description = "SOPS key containing the OIDC client environment variables";
        };
        domain = lib.mkOption {
          type = lib.types.str;
          default = "food.beinke.cloud";
          description = "Public domain for Mealie";
        };
      };

      config = {
        # Reuse the shared PostgreSQL dump hook and live-data backup exclusion.
        wat.thelegy.postgresql.enable = true;

        services.mealie = {
          enable = true;
          listenAddress = "127.0.0.1";
          port = 21254;
          database.createLocally = true;
          credentialsFile = lib.mkIf cfg.oidc.enable config.sops.secrets.${cfg.sopsSecretsFile}.path;
          extraOptions = [ "--forwarded-allow-ips=127.0.0.1" ];
          settings = {
            BASE_URL = "https://${cfg.domain}";
            ALLOW_SIGNUP = "false";
            TZ = config.time.timeZone;
          }
          // lib.optionalAttrs cfg.oidc.enable {
            OIDC_AUTH_ENABLED = "true";
            OIDC_CONFIGURATION_URL = cfg.oidc.configurationUrl;
            OIDC_PROVIDER_NAME = "Pocket ID";
            OIDC_SIGNUP_ENABLED = "true";
            OIDC_USER_CLAIM = "email";
            OIDC_REQUIRES_EMAIL_VERIFICATION = "true";
          };
        };

        sops.secrets.${cfg.sopsSecretsFile} = lib.mkIf cfg.oidc.enable {
          format = "yaml";
          mode = "0600";
          restartUnits = [ "mealie.service" ];
        };

        # The root filesystem backup includes /var/lib/private/mealie (assets)
        # and /var/backups/postgresql/full_dump.sql, just as it does for Matrix.
        wat.thelegy.traefik.dynamicConfigs.mealie.http = {
          services.mealie.loadBalancer.servers = [
            { url = "http://127.0.0.1:${toString config.services.mealie.port}"; }
          ];
          routers.mealie = {
            rule = "Host(`${cfg.domain}`)";
            service = "mealie";
          };
        };
      };
    }
  );
}
