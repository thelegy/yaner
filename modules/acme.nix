{ wat, ... }:
{
  flake.nixosModules.acme = wat.mkModule [ "acme" ] (
    {
      cfg,
      config,
      lib,
      ...
    }:

    {
      namespaceOptions = {

        staging = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };

        defaultCertName = lib.mkOption {
          type = lib.types.str;
          default = config.networking.fqdn;
        };

        extraDomainNames = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };

        sopsCredentialsFile = lib.mkOption {
          type = lib.types.str;
          default = "acme-credentials-file";
        };

        reloadUnits = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };

        dnsProvider = lib.mkOption {
          type = lib.types.str;
        };

      };
      config = {

        sops.secrets.${cfg.sopsCredentialsFile} = {
          format = "yaml";
          mode = "0600";
          restartUnits = [ "acme-${cfg.defaultCertName}.service" ];
        };

        security.acme = {
          acceptTerms = true;
          defaults.server = lib.mkIf (cfg.staging) "https://acme-staging-v02.api.letsencrypt.org/directory";
          defaults.email = "mail+letsencrypt@0jb.de";
          certs.${cfg.defaultCertName} = {
            inherit (cfg) extraDomainNames;
            dnsProvider = cfg.dnsProvider;
            environmentFile = config.sops.secrets.${cfg.sopsCredentialsFile}.path;
            postRun = lib.mkIf (lib.length cfg.reloadUnits > 0) ''
              systemctl reload-or-restart ${lib.concatStringsSep " " cfg.reloadUnits}
            '';
          };
        };

      };
    }

  );
}
