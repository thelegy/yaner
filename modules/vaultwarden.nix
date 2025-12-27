{
  mkModule,
  lib,
  liftToNamespace,
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
        default = "beinke.cloud";
      };

      domain = mkOption {
        type = types.str;
        default = "pw.${cfg.baseDomain}";
      };

      secretsFile = mkOption {
        type = with types; nullOr str;
        default =
          if isNull cfg.sopsSecretsFile then null else config.sops.secrets.${cfg.sopsSecretsFile}.path;
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
      user = config.users.users.vaultwarden.name;
      group = config.users.groups.vaultwarden.name;
      port = 8222;
      backupDir = "/var/lib/vaultwarden_backup";
    in
    {

      systemd.tmpfiles.rules = [ "d ${backupDir} 0700 ${user} ${group}" ];

      systemd.services.vaultwarden = {
        preStart = "rm -f $STATE_DIRECTORY/config.json";
        serviceConfig.SupplementaryGroups = mkIf sopsIsUsed [ "keys" ];
      };

      sops.secrets.${cfg.sopsSecretsFile} = mkIf sopsIsUsed {
        format = "yaml";
        group = group;
        mode = "0640";
        restartUnits = [ "vaultwarden.service" ];
      };

      services.vaultwarden = {
        enable = true;

        environmentFile = cfg.secretsFile;
        backupDir = backupDir;

        config = {
          ROCKET_ADDRESS = "::1";
          ROCKET_PORT = port;

          DOMAIN = "https://${cfg.domain}";
          SIGNUPS_ALLOWED = false;
        };
      };

      wat.thelegy.crowdsec = {
        enable = true;
        parsers = [ "Dominic-Wagner/vaultwarden-logs" ];
        scenarios = [ "Dominic-Wagner/vaultwarden-bf" ];
        journalctlFilters = [ "SYSLOG_IDENTIFIER=vaultwarden" ];
      };

      wat.thelegy.traefik.dynamicConfigs.vaultwarden = {
        http.services.vaultwarden = {
          loadBalancer.servers = [ { url = "http://[::1]:${toString port}"; } ];
        };
        http.routers.vaultwarden = {
          rule = "Host(`${cfg.domain}`)";
          tls.certResolver = "letsencrypt";
          service = "vaultwarden";
        };
      };

    };
}
