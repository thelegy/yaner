{ wat, ... }:
{
  flake.nixosModules.traefik = wat.mkModuleWrapped [ "traefik" ] (
    {
      cfg,
      config,
      lib,
      pkgs,
      ...
    }:
    with lib;

    let
      format = pkgs.formats.toml { };
    in
    {

      options = {

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
              log.level = "INFO";
              providers.file.directory = "/etc/traefik";
              api = { };
              experimental.plugins.traefik-oidc-auth = {
                moduleName = "github.com/sevensolutions/traefik-oidc-auth";
                version = "v0.22.0";
              };
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

          wat.thelegy.traefik.dynamicConfigs.oidc-host = {
            http.middlewares.oidc-host.plugin.traefik-oidc-auth = {
              Secret = "\${OIDC_ENCRYPTION_KEY}";
              Scopes = [ "openid" ];
              Provider = {
                Url = "https://auth.beinke.cloud";
                ClientId = "\${OIDC_HOST_CLIENT_ID}";
                ClientSecret = "\${OIDC_HOST_CLIENT_SECRET}";
                UsePkce = true;
              };
            };
          };

          wat.thelegy.traefik.dynamicConfigs.traefik-dashboard =
            let
              inherit (config.networking) fqdn;
            in
            {
              http.routers.traefik-dashboard = {
                rule = "Host(`traefik.${fqdn}`)";
                middlewares = [ "oidc-host@file" ];
                service = "api@internal";
                tls.certResolver = "letsencrypt";
                tls.domains = [
                  {
                    main = "*.${fqdn}";
                  }
                ];
              };
            };

        };
    }

  );
}
