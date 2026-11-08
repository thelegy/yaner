{ wat, ... }:
{
  flake.nixosModules.hosts = wat.mkModule [ "hosts" ] (
    {
      cfg,
      config,
      lib,
      ...
    }:

    {

      namespaceOptions = {
        hosts = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule (
              { name, config, ... }:
              {
                options = {
                  hostName = lib.mkOption { type = lib.types.str; };
                  ipv4Addresses = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    default = [ ];
                  };
                  ipv6Addresses = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    default = [ ];
                  };
                  ipv6Tailscale = lib.mkOption {
                    type = lib.types.nullOr lib.types.str;
                    default = null;
                  };
                  publicKey = lib.mkOption {
                    type = lib.types.nullOr lib.types.str;
                    default = null;
                  };
                };
                config = {
                  hostName = name;
                };
              }
            )
          );
          default = { };
        };
      };

      config =
        let
          nullableToList = x: if isNull x then [ ] else [ x ];
        in
        ((wat.toNamespace [ "hosts" ]) { hosts = lib.importJSON ./_hosts/hosts.json; })
        // {
          networking.hosts = lib.mkMerge (
            lib.mapAttrsToList (
              _: host:
              lib.genAttrs (
                if isNull host.ipv6Tailscale then
                  (host.ipv4Addresses ++ host.ipv6Addresses)
                else
                  [ host.ipv6Tailscale ]
              ) (_: [ host.hostName ])
            ) cfg.hosts
          );
          programs.ssh.knownHosts = lib.mapAttrs (_: host: {
            publicKey = host.publicKey;
            hostNames = [
              host.hostName
              "${host.hostName}.${config.networking.domain}"
            ]
            ++ host.ipv4Addresses
            ++ host.ipv6Addresses
            ++ (nullableToList host.ipv6Tailscale);
          }) (lib.filterAttrs (_: host: !isNull host.publicKey) cfg.hosts);
        };

    }

  );
}
