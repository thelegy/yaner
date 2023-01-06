{ mkModule
, config
, lib
, liftToNamespace
, ... }:
with lib;

mkModule {
  options = cfg: liftToNamespace {

    staging = mkOption {
      type = types.bool;
      default = true;
    };

    defaultCertName = mkOption {
      type = types.str;
      default = config.networking.fqdn;
    };

    extraDomainNames = mkOption {
      type = types.listOf types.str;
      default = [];
    };

    postRun = mkOption {
      type = types.lines;
      default = "";
    };

    sopsCredentialsFile = mkOption {
      type = types.str;
      default = "acme-credentials-file";
    };

  };
  config = cfg: {

    sops.secrets.${cfg.sopsCredentialsFile} = {
      format = "yaml";
      mode = "0600";
      restartUnits = [ "acme-${cfg.defaultCertName}.service" ];
    };

    security.acme = {
      acceptTerms = true;
      server = mkIf (!cfg.staging) "https://acme-staging-v02.api.letsencrypt.org/directory";
      defaults.email = "mail+letsencrypt@0jb.de";
      preliminarySelfsigned = false;
      certs.${cfg.defaultCertName} = {
        dnsProvider = "hurricane";
        credentialsFile = config.sops.secrets.${cfg.sopsCredentialsFile}.path;
        inherit (cfg) extraDomainNames postRun;
      };
    };

  };
}
