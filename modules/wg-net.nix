{ wat, ... }:
{
  flake.nixosModules.wg-net = (
    {
      lib,
      config,
      pkgs,
      ...
    }:

    let
      cfg = wat.fromNamespace [ "wg-net" ] config;
      hostName = config.networking.hostName;

      nodeConfigs =
        fileName:
        lib.pipe config.wat.machines [
          (lib.mapAttrs (_: v: v.${fileName}.file or null))
          (lib.filterAttrs (_: v: !isNull v))
          (lib.mapAttrs (_: import))
        ];

      nodeType =
        net:
        lib.types.submodule (
          { name, config, ... }:
          {
            options = {
              enable = lib.mkOption {
                description = "enable Wireguard network config layer";
                type = lib.types.bool;
                default = true;
              };
              name = lib.mkOption {
                type = lib.types.str;
              };
              publicKey = lib.mkOption {
                type = lib.types.str;
              };
              allowedIPs = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = lib.forEach config.addresses (
                  addr: "${lib.head (lib.strings.match "(.+)/[0-9]+" addr)}/32"
                );
              };
              address = lib.mkOption {
                type = lib.types.str;
              };
              addresses = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ config.address ];
              };
              port = lib.mkOption {
                type = lib.types.nullOr lib.types.port;
                default = net.defaultPort;
              };
              endpoint = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
              };
              persistentKeepalive = lib.mkOption {
                type = lib.types.int;
                default = 0;
              };
            };
            config = { inherit name; };
          }
        );

      netType = lib.types.submodule (
        { name, config, ... }:
        {
          options = {
            enable = lib.mkOption {
              description = "enable Wireguard network config layer";
              type = lib.types.bool;
              default = true;
            };
            name = lib.mkOption {
              type = lib.types.str;
            };
            configFileName = lib.mkOption {
              type = lib.types.str;
              default = "${name}-net.nix";
            };
            privateKeyFile = lib.mkOption {
              type = lib.types.str;
            };
            defaultPort = lib.mkOption {
              type = lib.types.port;
            };
            nodes = lib.mkOption {
              type = lib.types.attrsOf (nodeType config);
              internal = true;
            };
            thisNode = lib.mkOption {
              type = nodeType config;
              internal = true;
            };
          };
          config =
            let
              nodes = nodeConfigs config.configFileName;
            in
            {
              inherit name;
              nodes = lib.filterAttrs (k: _: k != hostName) nodes;
              thisNode = nodes.${hostName};
            };
        }
      );

    in
    {

      options = (wat.toNamespace [ "wg-net" ]) (
        lib.mkOption {
          type = lib.types.attrsOf netType;
          default = { };
        }
      );

      config =
        let
          nets = lib.attrValues cfg;
          anyNetEnabled = lib.any (x: x.enable) nets;

          enabledNets = lib.filter (x: x.enable) nets;
          enabledNetNames = map (x: x.name) enabledNets;
        in
        {

          assertions = [
            {
              message = "wg-net needs systemd-networkd enabled";
              assertion = anyNetEnabled -> config.systemd.network.enable;
            }
          ];

          environment.systemPackages = lib.mkIf anyNetEnabled [ pkgs.wireguard-tools ];

          systemd.network.netdevs = (
            lib.mapAttrs (
              _: net:
              lib.mkIf net.enable {
                netdevConfig.Name = net.name;
                netdevConfig.Kind = "wireguard";
                wireguardConfig.PrivateKeyFile = net.privateKeyFile;
                wireguardConfig.ListenPort = net.thisNode.port;
                wireguardPeers = lib.pipe net.nodes [
                  lib.attrValues
                  (lib.filter (node: node.enable))
                  (map (node: {
                    PublicKey = node.publicKey;
                    AllowedIPs = node.allowedIPs;
                    Endpoint =
                      let
                        noEndpoint = isNull node.endpoint;
                        noPort = isNull node.port;
                        noColon = isNull (lib.strings.match ".*:.*" node.endpoint);
                      in
                      lib.mkIf (!noEndpoint) (
                        if noEndpoint || noPort || !noColon then node.endpoint else "${node.endpoint}:${toString node.port}"
                      );
                    PersistentKeepalive = net.thisNode.persistentKeepalive;
                  }))
                ];
              }
            ) cfg
          );

          systemd.network.networks = (
            lib.mapAttrs (
              _: net:
              lib.mkIf net.enable {
                name = net.name;
                address = net.thisNode.addresses;
              }
            ) cfg
          );

          #systemd.network.wait-online.ignoredInterfaces = enabledNetNames;

          networking.networkmanager.unmanaged = enabledNetNames;

          networking.firewall.allowedUDPPorts = map (x: x.thisNode.port) enabledNets;

        };

    }

  );
}
