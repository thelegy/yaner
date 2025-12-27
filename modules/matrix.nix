{
  mkModule,
  lib,
  liftToNamespace,
  extractFromNamespace,
  config,
  pkgs,
  ...
}:
with lib;

mkModule {

  options =
    cfg:
    liftToNamespace {

      baseDomain = mkOption {
        type = types.str;
        default = "0jb.de";
      };

      matrixDomain = mkOption {
        type = types.str;
        default = "matrix.${cfg.baseDomain}";
      };

      elementDomain = mkOption {
        type = types.str;
        default = "element.${cfg.baseDomain}";
      };

      secretsFile = mkOption {
        type = types.str;
        default =
          if isNull cfg.sopsSecretsFile then
            "${config.services.matrix-synapse.dataDir}/secrets.yml"
          else
            config.sops.secrets.${cfg.sopsSecretsFile}.path;
      };

      sopsSecretsFile = mkOption {
        type = types.nullOr types.str;
        default = null;
      };

    };

  config =
    cfg:
    let
      sopsIsUsed = !isNull cfg.sopsSecretsFile;
    in
    {

      systemd.services.matrix-synapse.serviceConfig.SupplementaryGroups = mkIf sopsIsUsed [ "keys" ];

      sops.secrets.${cfg.sopsSecretsFile} = mkIf sopsIsUsed {
        format = "yaml";
        group = "matrix-synapse";
        mode = "0640";
      };

      environment.systemPackages = [
        config.services.postgresql.package
        config.services.matrix-synapse.package
      ];

      wat.thelegy.postgresql.enable = true;
      services.postgresql.ensureUsers = [
        {
          name = "matrix-synapse";
        }
      ];

      # Matrix Server
      services.matrix-synapse = {
        enable = true;
        log.root.level = "WARNING";

        extras = mkForce [
          "systemd"
          "postgres"
          "url-preview"
        ];

        settings = {
          server_name = cfg.baseDomain;
          database.name = "psycopg2";
          enable_metrics = true;
          listeners = [
            {
              port = 8008;
              resources = [
                {
                  compress = false;
                  names = [
                    "client"
                    "federation"
                  ];
                }
              ];
              tls = false;
              type = "http";
              x_forwarded = true;
            }
            {
              port = 9008;
              resources = [ ];
              tls = false;
              bind_addresses = [ "127.0.0.1" ];
              type = "metrics";
            }
          ];

          allow_guest_access = false;
          enable_registration = false;
          url_preview_enabled = true;
          expire_access_token = true;
          delete_stale_devices_after = "180d";
        };

        extraConfigFiles = [
          cfg.secretsFile
        ];
      };

      wat.thelegy.traefik.dynamicConfigs.matrix = {
        http.services.matrix = {
          loadBalancer.servers = [ { url = "http://[::1]:8008"; } ];
        };
        http.services.matrix-wellknown = {
          loadBalancer.servers = [ { url = "http://matrix-wellknown.localhost:5128"; } ];
          loadBalancer.passHostHeader = false;
        };
        http.middlewares = {
          redirect-to-element.redirectRegex = {
            regex = "^https?://([^/]*)/$";
            replacement = "https://${cfg.elementDomain}";
          };
        };
        http.routers.matrix = {
          rule = "Host(`${cfg.matrixDomain}`)";
          tls.certResolver = "letsencrypt";
          middlewares = [ "redirect-to-element" ];
          service = "matrix";
        };
        http.routers.element = {
          rule = "Host(`${cfg.elementDomain}`)";
          tls.certResolver = "letsencrypt";
          service = "nginx";
        };
        http.routers.matrix-wellknown = {
          rule = "Host(`${cfg.baseDomain}`) && PathPrefix(`/.well-known/matrix`)";
          tls.certResolver = "letsencrypt";
          service = "matrix-wellknown";
        };
      };

      # Element Web
      services.nginx.virtualHosts.${cfg.elementDomain} =
        let
          config = {
            default_server_name = cfg.baseDomain;
            disable_login_language_selector = true;
            disable_3pid_login = true;
            disable_custom_urls = true;
            disable_guests = true;
            show_labs_settings = true;
            enable_presence_by_hs_url = {
              "https://matrix-client.matrix.org" = false;
              "https://matrix.org" = false;
            };
          };
        in
        {
          root = pkgs.element-web;
          locations."/config.json".extraConfig = ''
            default_type application/json;
            return 200 '${builtins.toJSON config}';
          '';
        };

      # Well known connectivity
      services.nginx.virtualHosts."matrix-wellknown.localhost" = {
        locations =
          let
            wellKnownClient = {
              "m.homeserver".base_url = "https://${cfg.matrixDomain}";
              "m.identity_server".base_url = "";
            };
            wellKnownServer = {
              "m.server" = "${cfg.matrixDomain}:443";
            };
            headers = ''
              default_type application/json;
              add_header 'Access-Control-Allow-Origin' '*';
              add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS';
              add_header 'Access-Control-Allow-Headers' 'X-Requested-With, Content-Type, Authorization';
            '';
          in
          {
            "/.well-known/matrix/client".extraConfig = ''
              ${headers}
              return 200 '${builtins.toJSON wellKnownClient}';
            '';
            "/.well-known/matrix/server".extraConfig = ''
              ${headers}
              return 200 '${builtins.toJSON wellKnownServer}';
            '';
          };
      };

      environment.etc."alloy/synapse-exporter.alloy".text = ''
        prometheus.scrape "synapse" {
          targets = [{"__address__" = "localhost:9008"}]
          forward_to = [prometheus.remote_write.default.receiver]
        }
      '';

    };

}
