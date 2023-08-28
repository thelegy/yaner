{ mkModule
, config
, lib
, liftToNamespace
, ...
}:
with lib;
mkModule {

  options = cfg: liftToNamespace {
    hosts = mkOption {
      type = types.attrsOf (types.submodule ({ name, config, ... }: {
        options = {
          hostName = mkOption { type = types.str; };
          ipv4Addresses = mkOption { type = types.listOf types.str; default = [ ]; };
          ipv6Addresses = mkOption { type = types.listOf types.str; default = [ ]; };
          publicKey = mkOption { type = types.nullOr types.str; default = null; };
        };
        config = { hostName = name; };
      }));
      default = { };
    };
  };

  config = cfg:
    (liftToNamespace { hosts = importJSON ./hosts.json; })
    //
    {
      networking.hosts = mkMerge
        (mapAttrsToList
          (_: host: genAttrs (host.ipv4Addresses ++ host.ipv6Addresses) (_: [ host.hostName ]))
          cfg.hosts);
      programs.ssh.knownHosts =
        mapAttrs
          (_: host: {
            publicKey = host.publicKey;
            hostNames = [
              host.hostName
              "${host.hostName}.${config.networking.domain}"
            ] ++ host.ipv4Addresses ++ host.ipv6Addresses;
          })
          (filterAttrs (_: host: !isNull host.publicKey) cfg.hosts);
    };

}
