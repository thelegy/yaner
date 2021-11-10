{ mkModule
, lib
, liftToNamespace
, extractFromNamespace
, config
, pkgs
, ... }:
with lib;

mkModule {

  options = let
    cfg = extractFromNamespace config;
  in liftToNamespace {

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

    nginxBaseVirtualhost = mkOption {
      type = types.str;
      default = cfg.baseDomain;
    };

    useACMEHost = mkOption {
      type = with types; nullOr str;
      default = null;
    };

    secretsFile = mkOption {
      type = types.str;
      default = "${config.services.matrix-synapse.dataDir}/secrets.yml";
    };

  };

  config = cfg: {

    # Matrix Server
    services.matrix-synapse = {
      enable = true;
      database_type = "sqlite3";
      server_name = cfg.baseDomain;
      public_baseurl = "https://${cfg.matrixDomain}";
      no_tls = true;
      listeners = [{
        bind_address = "::1";
        port = 8008;
        resources = [
          { compress = true; names = [ "client" ]; }
          { compress = false; names = [ "federation" ]; }
        ];
        tls = false;
        type = "http";
        x_forwarded = true;
      }];

      allow_guest_access = false;
      enable_registration = false;
      url_preview_enabled = true;
      expire_access_token = true;
      extraConfig = ''
        use_presence: true
        enable_group_creation: true
        group_creation_prefix: "unofficial/"
        acme:
          enabled: false
      '';

      extraConfigFiles = [
        cfg.secretsFile
      ];
    };

    # Matrix availability
    services.nginx.virtualHosts.${cfg.matrixDomain} = {
      forceSSL = true;
      useACMEHost = cfg.useACMEHost;
      locations."/".extraConfig = "return 404;";  # ???
      locations."/_matrix".proxyPass = "http://[::1]:8008";
    };

    # Element Web
    services.nginx.virtualHosts.${cfg.elementDomain} = {
      forceSSL = true;
      useACMEHost = cfg.useACMEHost;
      root = pkgs.element-web.override {
        conf = {
          default_server_config."m.homeserver" = {
            "base_url" = "https://${cfg.matrixDomain}";
            "server_name" = "https://${cfg.baseDomain}";
          };
          disable_custom_urls = true;
          disable_3pid_login = true;
          showLabsSettings = true;
          default_theme = "dark";
        };
      };
    };

    # Well known connectivity
    services.nginx.virtualHosts.${cfg.nginxBaseVirtualhost}.locations = let
      wellKnownClient = {
        "m.homeserver".base_url = "https://${cfg.matrixDomain}";
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
    in {
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

}
