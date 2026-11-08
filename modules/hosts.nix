{ wat, ... }:
{
  flake.nixosModules.hosts = wat.mkModuleWrapped [ "hosts" ] (
    {
      cfg,
      config,
      lib,
      ...
    }:
    with lib;
    {

      options = {
        hosts = mkOption {
          type = types.attrsOf (
            types.submodule (
              { name, config, ... }:
              {
                options = {
                  hostName = mkOption { type = types.str; };
                  ipv4Addresses = mkOption {
                    type = types.listOf types.str;
                    default = [ ];
                  };
                  ipv6Addresses = mkOption {
                    type = types.listOf types.str;
                    default = [ ];
                  };
                  ipv6Tailscale = mkOption {
                    type = types.nullOr types.str;
                    default = null;
                  };
                  publicKey = mkOption {
                    type = types.nullOr types.str;
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
        ((wat.toNamespace [ "hosts" ]) { hosts = importJSON ./_hosts/hosts.json; })
        // {
          networking.hosts = mkMerge (
            mapAttrsToList (
              _: host:
              genAttrs (
                if isNull host.ipv6Tailscale then
                  (host.ipv4Addresses ++ host.ipv6Addresses)
                else
                  [ host.ipv6Tailscale ]
              ) (_: [ host.hostName ])
            ) cfg.hosts
          );
          programs.ssh.knownHosts = mapAttrs (_: host: {
            publicKey = host.publicKey;
            hostNames = [
              host.hostName
              "${host.hostName}.${config.networking.domain}"
            ]
            ++ host.ipv4Addresses
            ++ host.ipv6Addresses
            ++ (nullableToList host.ipv6Tailscale);
          }) (filterAttrs (_: host: !isNull host.publicKey) cfg.hosts);
        };

    }

  );
}
