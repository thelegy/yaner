{ lib
, pkgs
, ... }: with lib;


let
  local_ip = "127.0.0.60";
  local_port = 3000;
  domain = "grafana.0jb.de";
in {

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_14;
    extraPlugins = with pkgs.postgresql_14.pkgs; [
      postgis
      timescaledb
    ];
    initdbArgs = [
      "--encoding=UTF8"
    ];
    ensureDatabases = [
      "grafana"
      "timescaledb"
    ];
    ensureUsers = [
      {
        name = "grafana";
        # Not supported any longer
        #ensurePermissions = {
        #  "DATABASE \"grafana\"" = "ALL PRIVILEGES";
        #  "DATABASE \"timescaledb\"" = "CONNECT";
        #  "ALL TABLES IN SCHEMA public" = "SELECT";
        #};
      }
    ];
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        domain = domain;
        root_url = "https://${domain}/";
        http_addr = local_ip;
        http_port = local_port;
      };
      database = {
        type = "postgres";
        user = "grafana";
        host = "/var/run/postgresql/";
      };
    };
    provision.enable = true;
    provision.datasources.settings.datasources = [
      {
        name = "timescaledb";
        isDefault = true;
        type = "postgres";
        url = "/var/run/postgresql";
        database = "timescaledb";
        user = "grafana";
        jsonData.timescaledb = true;
        jsonData.postgresVersion = 1400;
      }
      {
        name = "prometheus";
        type = "prometheus";
        url = "https://prometheus.0jb.de:9090/";
      }
    ];
    provision.dashboards.settings.providers = [
      {
        name = "yaner dashboards";
        options.path = ./dashboards;
        options.foldersFromFilesStructure = true;
        # Nix store is constant so no update is ever needed
        updateIntervalSeconds = 999999999;
      }
    ];
  };

  wat.thelegy.monitoring.scrapeConfigs.grafana = {
    static_configs = [
      {
        targets = [ "${local_ip}:${toString local_port}" ];
      }
    ];
  };

  services.nginx.virtualHosts.${domain} = {
    locations."/" = {
      proxyPass = "http://${local_ip}:${toString local_port}/";
      proxyWebsockets = true;
    };
  };

}
