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
        type = types.nullOr types.str;
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

  config =
    cfg:
    let
      nft_firewall = config.networking.nftables.firewall.enable;
      allowedTCPPorts = [
        80
        443
      ];
      allowedUDPPorts = [
        443
      ];
    in
    {
      networking.nftables.firewall.rules.traefik = {
        from = mkDefault "all";
        to = [ "fw" ];
        inherit allowedTCPPorts allowedUDPPorts;
      };
      networking.firewall = mkIf (!nft_firewall) {
        inherit allowedTCPPorts allowedUDPPorts;
      };

      sops.secrets.${cfg.sopsCredentialsFile} = {
        format = "yaml";
        mode = "0600";
        restartUnits = [ "traefik.service" ];
      };

      systemd.services.traefik = mkIf (!isNull cfg.sopsCredentialsFile) {
        serviceConfig.EnvironmentFile = config.sops.secrets.${cfg.sopsCredentialsFile}.path;
      };

      environment.etc = mkMerge [
        (mapAttrs' (
          k: v:
          nameValuePair "traefik/${k}.toml" {
            mode = "0644";
            source = format.generate "traefik-${k}.toml" v;
          }
        ) cfg.dynamicConfigs)
        {
          "alloy/traefik-exporter.alloy".text = ''
            prometheus.scrape "traefik" {
              targets = [{"__address__" = "127.0.0.1:13255"}]
              forward_to = [prometheus.relabel.default.receiver]
            }
          '';

        }
      ];

      services.traefik = {
        enable = true;
        staticConfigOptions = {
          providers.file.directory = "/etc/traefik";
          entryPoints = {
            web = {
              address = mkDefault ":80";
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
              address = mkDefault ":443";
              asDefault = mkDefault true;
              http.tls.certResolver = "letsencrypt";
              http3 = true;
            };
            traefik = {
              address = "127.0.0.1:13255";
              observability = {
                accessLogs = false;
                metrics = false;
                tracing = false;
              };
            };
          };
          metrics = {
            prometheus = { };
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
