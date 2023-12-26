{
  config,
  lib,
  mkTrivialModule,
  ...
}:
with lib; let
  domain = "loki.0jb.de";
  acmeHost = config.networking.fqdn;
  ip = "[::1]";
  localPort = 3099;
  remotePort = 3100;
in
  mkTrivialModule {
    wat.thelegy.acme.extraDomainNames = [domain];

    services.loki = {
      enable = true;
      extraFlags = [
        "-target=all"
      ];
      configuration = {
        common = {
          ring = {
            instance_addr = "::1";
            kvstore.store = "inmemory";
          };
          replication_factor = 1;
        };
        auth_enabled = false;
        server = {
          http_listen_address = ip;
          http_listen_port = localPort;
          log_level = "warn";
        };
        compactor = {
          working_directory = "compactor";
          compaction_interval = "10m";
          retention_enabled = true;
          retention_delete_delay = "2h";
          retention_delete_worker_count = 150;
        };
        limits_config = {
          retention_period = "90d";
        };
        schema_config.configs = [
          {
            from = "2020-01-01";
            index = {
              prefix = "index_";
              period = "24h";
            };
            store = "tsdb";
            object_store = "filesystem";
            schema = "v12";
          }
        ];
        storage_config = {
          filesystem.directory = "storage";
          tsdb_shipper = {
            active_index_directory = "tsdb-index";
            cache_location = "tsdb-cache";
          };
        };
      };
    };

    services.nginx.virtualHosts.${domain} = {
      listen = [
        {
          addr = "[::]";
          port = remotePort;
          ssl = true;
        }
      ];
      forceSSL = true;
      useACMEHost = acmeHost;
      locations."/" = {
        proxyPass = "http://${ip}:${toString localPort}";
        recommendedProxySettings = true;
        proxyWebsockets = true;
      };
    };

    networking.nftables.firewall.rules.loki = {
      from = ["tailscale"];
      to = ["fw"];
      allowedTCPPorts = [remotePort];
    };
  }
