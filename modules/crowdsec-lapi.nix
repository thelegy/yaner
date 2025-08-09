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
  acmeHost = config.networking.fqdn;
  lapi_credentials_path = "/etc/crowdsec/local_api_credentials.yaml";
  port = 8080;
  yaml = pkgs.formats.yaml { };
in
mkModule {
  options = liftToNamespace { };

  config =
    cfg:
    let
      domain = config.wat.thelegy.crowdsec.lapiDomain;
      confDir = pkgs.runCommandLocal "crowdsec-lapi-config" { } ''
        mkdir $out
        ln -s ${pkgs.crowdsec}/share/crowdsec/config/patterns $out/
        ln -s ${pkgs.crowdsec}/share/crowdsec/config/simulation.yaml $out/
        ln -s ${pkgs.crowdsec}/share/crowdsec/config/profiles.yaml $out/
      '';
      mainConfig = yaml.generate "crowdsec-lapi.yaml" {
        common = {
          daemonize = true;
          log_media = "stdout";
          log_level = "info";
        };
        config_paths = {
          config_dir = "${confDir}";
          data_dir = "\$STATE_DIRECTORY";
        };
        crowdsec_service = {
          enable = false;
        };
        db_config = {
          type = "sqlite";
          db_path = "\$STATE_DIRECTORY/crowdsec.db";
          use_wal = true;
        };
        api.client = {
          insecure_skip_verify = false;
          credentials_path = lapi_credentials_path;
        };
        api.server = {
          enable = true;
          listen_uri = "127.0.0.1:${toString port}";
          profiles_path = "${confDir}/profiles.yaml";
        };
        prometheus = {
          enabled = true;
          level = "full";
          listen_addr = "127.0.0.1";
          listen_port = 6059;
        };
      };
      cscli-lapi = pkgs.writeScriptBin "cscli-lapi" ''
        #!/bin/sh
        STATE_DIRECTORY=/var/lib/crowdsec-lapi exec ${pkgs.crowdsec}/bin/cscli -c ${mainConfig} "$@"
      '';
    in
    {
      wat.thelegy.acme.extraDomainNames = [ domain ];

      wat.thelegy.crowdsec.enable = true;
      environment.systemPackages = [ cscli-lapi ];

      sops.secrets.${config.wat.thelegy.crowdsec.sopsLapiCredentialsFile}.restartUnits = [
        "crowdsec-lapi.service"
      ];

      systemd.services.crowdsec-lapi = {
        description = "Crowdsec local api server";
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "notify";
          ExecStart = "${pkgs.crowdsec}/bin/crowdsec -c ${mainConfig}";
          Environment = "LC_ALL=C LANG=C";
          Restart = "always";
          RestartSec = 60;
          DynamicUser = true;
          StateDirectory = "crowdsec-lapi";
          SyslogIdentifier = "crowdsec-lapi";
        };
      };

      services.nginx.virtualHosts.${domain} = {
        forceSSL = true;
        useACMEHost = acmeHost;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString port}";
          recommendedProxySettings = true;
          proxyWebsockets = true;
        };
      };
    };
}
