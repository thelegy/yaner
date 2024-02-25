{
  config,
  lib,
  liftToNamespace,
  mkModule,
  pkgs,
  ...
}:
with lib;
  mkModule {
    options = cfg:
      liftToNamespace {
        role = mkOption {
          type = types.enum ["proxy" "satelite"];
        };
        name = mkOption {
          type = types.str;
        };
        transportZone = mkOption {
          type = types.str;
          default = "static";
        };
        transportNetwork = mkOption {
          type = types.str;
          default = "static";
        };
        internetNetwork = mkOption {
          type = types.str;
          default = "default";
        };
        tableId = mkOption {
          type = types.number;
        };
        staticIp = mkOption {
          type = types.str;
        };
        internalProxyIp = mkOption {
          type = types.str;
        };
        internalSateliteIp = mkOption {
          type = types.str;
        };
        proxyIp = mkOption {
          type = types.str;
        };
        sateliteIp = mkOption {
          type = types.str;
        };
      };
    config = cfg: let
      isProxy = cfg.role == "proxy";
      isSatelite = cfg.role != "proxy";
      localIp =
        if isProxy
        then cfg.proxyIp
        else cfg.sateliteIp;
      remoteIp =
        if isProxy
        then cfg.sateliteIp
        else cfg.proxyIp;
      localTunnelIp =
        if isProxy
        then cfg.internalProxyIp
        else cfg.internalSateliteIp;
      remoteTunnelIp =
        if isProxy
        then cfg.internalSateliteIp
        else cfg.internalProxyIp;
    in {
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
          (mkIf isSatelite "${cfg.staticIp}/32")
        ];
        linkConfig.RequiredForOnline = "no";
        networkConfig.IPForward = mkIf isProxy "ipv4";
        routes = [
          (mkIf isSatelite {
            routeConfig = {
              Table = cfg.tableId;
              Gateway = cfg.internalProxyIp;
            };
          })
          (mkIf isProxy {
            routeConfig = {
              Destination = cfg.staticIp;
              Gateway = cfg.internalSateliteIp;
            };
          })
        ];
        routingPolicyRules = mkIf isSatelite [
          {
            routingPolicyRuleConfig = {
              Family = "ipv4";
              From = cfg.staticIp;
              Table = "main";
              SuppressPrefixLength = 0;
            };
          }
          {
            routingPolicyRuleConfig = {
              Family = "ipv4";
              From = cfg.staticIp;
              Table = cfg.tableId;
            };
          }
        ];
      };

      systemd.network.networks.${cfg.internetNetwork}.networkConfig.IPv4ProxyARP = mkIf isProxy true;

      networking.nftables.firewall = {
        zones."${cfg.name}-interface".interfaces = [cfg.name];
        zones.${cfg.name} = {
          ipv4Addresses = [cfg.staticIp];
        };
        rules."${cfg.name}-spoofing" = mkIf isSatelite {
          from = ["${cfg.name}-interface"];
          to = "all";
          ruleType = "ban";
          extraLines = [
            "ip daddr ${cfg.staticIp} return"
            "counter drop"
          ];
        };
        rules."${cfg.name}-proxy" = mkIf isProxy {
          from = "all";
          to = [cfg.name];
          extraLines = ["counter accept"];
        };
      };
    };
  }
