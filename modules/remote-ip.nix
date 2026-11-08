{ wat, ... }:
{
  flake.nixosModules.remote-ip = wat.mkModule [ "remote-ip" ] (
    {
      cfg,
      config,
      lib,
      pkgs,
      ...
    }:

    {
      namespaceOptions = {
        role = lib.mkOption {
          type = lib.types.enum [
            "proxy"
            "satelite"
          ];
        };
        name = lib.mkOption {
          type = lib.types.str;
        };
        transportZone = lib.mkOption {
          type = lib.types.str;
          default = "static";
        };
        transportNetwork = lib.mkOption {
          type = lib.types.str;
          default = "static";
        };
        internetNetwork = lib.mkOption {
          type = lib.types.str;
          default = "default";
        };
        tableId = lib.mkOption {
          type = lib.types.number;
        };
        staticIp = lib.mkOption {
          type = lib.types.str;
        };
        internalProxyIp = lib.mkOption {
          type = lib.types.str;
        };
        internalSateliteIp = lib.mkOption {
          type = lib.types.str;
        };
        proxyIp = lib.mkOption {
          type = lib.types.str;
        };
        sateliteIp = lib.mkOption {
          type = lib.types.str;
        };
      };
      config =
        let
          isProxy = cfg.role == "proxy";
          isSatelite = cfg.role != "proxy";
          localIp = if isProxy then cfg.proxyIp else cfg.sateliteIp;
          remoteIp = if isProxy then cfg.sateliteIp else cfg.proxyIp;
          localTunnelIp = if isProxy then cfg.internalProxyIp else cfg.internalSateliteIp;
          remoteTunnelIp = if isProxy then cfg.internalSateliteIp else cfg.internalProxyIp;
        in
        {
          systemd.network.netdevs.${cfg.name} = {
            netdevConfig = {
              Kind = "gre";
              Name = "${cfg.name}";
            };
            tunnelConfig = {
              Local = localIp;
              Remote = remoteIp;
            };
          };
          systemd.network.networks.${cfg.transportNetwork}.networkConfig.Tunnel = cfg.name;
          systemd.network.networks.${cfg.name} = {
            matchConfig.Name = cfg.name;
            address = [
              "${localTunnelIp}/30"
              (lib.mkIf isSatelite "${cfg.staticIp}/32")
            ];
            linkConfig.RequiredForOnline = "no";
            networkConfig.IPv4Forwarding = lib.mkIf isProxy true;
            routes = [
              (lib.mkIf isSatelite {
                Table = cfg.tableId;
                Gateway = cfg.internalProxyIp;
              })
              (lib.mkIf isProxy {
                Destination = cfg.staticIp;
                Gateway = cfg.internalSateliteIp;
              })
            ];
            routingPolicyRules = lib.mkIf isSatelite [
              {
                routingPolicyRuleConfig = {
                  Family = "ipv4";
                  From = cfg.staticIp;
                  Table = "main";
                  Priority = 12000;
                  SuppressPrefixLength = 0;
                };
              }
              {
                routingPolicyRuleConfig = {
                  Family = "ipv4";
                  From = cfg.staticIp;
                  Table = cfg.tableId;
                  Priority = 12500;
                };
              }
            ];
          };

          systemd.network.networks.${cfg.internetNetwork}.networkConfig = lib.mkIf isProxy {
            IPv4Forwarding = true;
            IPv4ProxyARP = true;
          };

          networking.nftables.firewall = {
            zones."${cfg.name}-interface".interfaces = [ cfg.name ];
            zones.${cfg.name} = {
              ipv4Addresses = [ cfg.staticIp ];
            };
            rules."${cfg.name}-spoofing" = lib.mkIf isSatelite {
              from = [ "${cfg.name}-interface" ];
              to = "all";
              ruleType = "ban";
              extraLines = [
                "ip daddr ${cfg.staticIp} return"
                "counter drop"
              ];
            };
            rules."${cfg.name}-proxy" = lib.mkIf isProxy {
              from = "all";
              to = [ cfg.name ];
              extraLines = [ "counter accept" ];
            };
          };
        };
    }

  );
}
