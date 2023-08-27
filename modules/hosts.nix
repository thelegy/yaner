{ mkModule
, config
, lib
, liftToNamespace
, ...
}:
with lib;
mkModule {

  config = cfg: (liftToNamespace
    {
      hosts = {

      };
    }) // {
    networking.hosts = mkMerge
      (mapAttrsToList
        (_: host: genAttrs host.addresses (_: [ host.hostName ]))
        cfg.hosts);
    programs.ssh.knownHosts =
      mapAttrs
        (_: host: { publicKey = host.publicKey; hostNames = [ host.hostName "${host.hostName}.${config.networking.domain}" ] ++ host.addresses; })
        (filterAttrs (_: host: !isNull host.publicKey) cfg.hosts);
  };

  options = cfg: liftToNamespace {
    hosts = mkOption {
      type = types.attrsOf (types.submodule ({ name, config, ... }: {
        options = {
          hostName = mkOption { type = types.str; };
          addresses = mkOption { type = types.listOf types.str; default = [ ]; };
          publicKey = mkOption { type = types.nullOr types.str; default = null; };
        };
        config = { hostName = name; };
      }));
      default = { };
    };
  };

}
