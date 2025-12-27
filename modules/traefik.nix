{
  config,
  lib,
  liftToNamespace,
  mkModule,
  pkgs,
  ...
}:
with lib;

let
  format = pkgs.formats.toml { };
in
mkModule {

  options =
    cfg:
    liftToNamespace {

      sopsCredentialsFile = mkOption {
        type = types.str;
        default = "traefik-env";
      };

      dynamicConfigs = mkOption {
        type = types.attrsOf format.type;
        default = {
          empty = { };
        };
      };

      dnsProvider = mkOption {
        type = types.str;
      };

    };

  config = cfg: {
    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
    networking.firewall.allowedUDPPorts = [
      443
    ];

    sops.secrets.${cfg.sopsCredentialsFile} = {
      format = "yaml";
      mode = "0600";
      restartUnits = [ "traefik.service" ];
    };

    systemd.services.traefik = {
      serviceConfig.EnvironmentFile = config.sops.secrets.${cfg.sopsCredentialsFile}.path;
    };

    environment.etc = mapAttrs' (
      k: v:
      nameValuePair "traefik/${k}.toml" {
        mode = "0644";
        source = format.generate "nixos.toml" v;
      }
    ) cfg.dynamicConfigs;

    services.traefik = {
      enable = true;
      staticConfigOptions = {
        providers.file.directory = "/etc/traefik";
        entryPoints = {
          web = {
            address = ":80";
            http.redirections.entryPoint = {
              to = "websecure";
              scheme = "https";
              permanent = true;
            };
            observability = {
              accessLogs = false;
              metrics = false;
              tracing = false;
            };
          };
          websecure = {
            address = ":443";
            asDefault = true;
            http = {
              tls = { };
            };
            http3 = true;
          };
        };
        certificatesResolvers = rec {
          letsencrypt.acme = {
            email = "mail+letsencrypt@0jb.de";
            storage = "/var/lib/traefik/acme.json";
            keyType = "EC256";
            caServer = "https://acme-v02.api.letsencrypt.org/directory";
            dnsChallenge = {
              provider = cfg.dnsProvider;
            };
          };
          letsencrypt-staging = recursiveUpdate letsencrypt {
            acme.storage = "/var/lib/traefik/acme-staging.json";
            acme.caServer = "https://acme-staging-v02.api.letsencrypt.org/directory";
          };
        };
      };
    };
  };

}
