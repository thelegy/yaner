{ mkModule
, extractFromNamespace
, lib
, liftToNamespace
, config
, pkgs
, ...
}: with lib;

let
  cfg = extractFromNamespace config;
  hostName = config.networking.hostName;

  nodeConfigs = fileName: pipe config.wat.machines [
    (mapAttrs (_: v: v.${fileName}.file or null))
    (filterAttrs (_: v: ! isNull v))
    (mapAttrs (_: import))
  ];

  nodeType = net: types.submodule ({ name, config, ... }: {
    options = {
      enable = mkOption {
        description = "enable Wireguard network config layer";
        type = types.bool;
        default = true;
      };
      name = mkOption {
        type = types.str;
      };
      publicKey = mkOption {
        type = types.str;
      };
      allowedIPs = mkOption {
        type = types.listOf types.str;
        default = forEach config.addresses (addr: "${head (strings.match "(.+)/[0-9]+" addr)}/32");
      };
      address = mkOption {
        type = types.str;
      };
      addresses = mkOption {
        type = types.listOf types.str;
        default = [ config.address ];
      };
      port = mkOption {
        type = types.nullOr types.port;
        default = net.defaultPort;
      };
      endpoint = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      persistentKeepalive = mkOption {
        type = types.int;
        default = 0;
      };
    };
    config = { inherit name; };
  });

  netType = types.submodule ({ name, config, ... }: {
    options = {
      enable = mkOption {
        description = "enable Wireguard network config layer";
        type = types.bool;
        default = true;
      };
      name = mkOption {
        type = types.str;
      };
      configFileName = mkOption {
        type = types.str;
        default = "${name}-net.nix";
      };
      privateKeyFile = mkOption {
        type = types.str;
      };
      defaultPort = mkOption {
        type = types.port;
      };
      nodes = mkOption {
        type = types.attrsOf (nodeType config);
        internal = true;
      };
      thisNode = mkOption {
        type = nodeType config;
        internal = true;
      };
    };
    config = let
      nodes = nodeConfigs config.configFileName;
    in {
      inherit name;
      nodes = filterAttrs (k: _: k != hostName) nodes;
      thisNode = nodes.${hostName};
    };
  });

in {

  options = liftToNamespace (mkOption {
    type = types.attrsOf netType;
    default = {};
  });

  config = let
    nets = attrValues cfg;
    anyNetEnabled = any (x: x.enable) nets;

    enabledNets = filter (x: x.enable) nets;
    enabledNetNames = map (x: x.name) enabledNets;
  in {

    assertions = [
      {
        message = "wg-net needs systemd-networkd enabled";
        assertion = anyNetEnabled -> config.systemd.network.enable;
      }
    ];

    environment.systemPackages = mkIf anyNetEnabled [ pkgs.wireguard-tools ];

    systemd.network.netdevs = (mapAttrs (_: net: mkIf net.enable {
      netdevConfig.Name = net.name;
      netdevConfig.Kind = "wireguard";
      wireguardConfig.PrivateKeyFile = net.privateKeyFile;
      wireguardConfig.ListenPort = net.thisNode.port;
      wireguardPeers = pipe net.nodes [
        attrValues
        (filter (node: node.enable))
        (map (node: {
          PublicKey = node.publicKey;
          AllowedIPs = node.allowedIPs;
          Endpoint = let
            noEndpoint = isNull node.endpoint;
            noPort = isNull node.port;
            noColon = isNull (strings.match ".*:.*" node.endpoint);
          in mkIf (!noEndpoint) (
            if noEndpoint || noPort || ! noColon
            then node.endpoint
            else "${node.endpoint}:${toString node.port}"
          );
          PersistentKeepalive = net.thisNode.persistentKeepalive;
        }))
      ];
    }) cfg);

    systemd.network.networks = (mapAttrs (_: net: mkIf net.enable {
      name = net.name;
      address = net.thisNode.addresses;
    }) cfg);

    #systemd.network.wait-online.ignoredInterfaces = enabledNetNames;

    networking.networkmanager.unmanaged = enabledNetNames;

    networking.firewall.allowedUDPPorts = map (x: x.thisNode.port) enabledNets;

  };

}
