{
  lib,
  liftToNamespace,
  mkModule,
  ...
}:
with lib;
  mkModule {
    options = cfg:
      liftToNamespace {
        role = mkOption {
          type = types.enum ["proxy" "satelite"];
        };
      };
    config = cfg: let
      isProxy = cfg.role == "proxy";
      name = "static-y";
      bandwidth =
        if isProxy
        then ""
        else "20M";
    in {
      wat.thelegy.static-net.enable = true;
      wat.thelegy.remote-ip = {
        enable = true;
        role = cfg.role;
        name = name;
        tableId = 43576;
        staticIp = "195.201.46.105";
        internalProxyIp = "192.168.243.2";
        internalSateliteIp = "192.168.243.1";
        proxyIp = "192.168.242.1";
        sateliteIp = "192.168.242.2";
      };
      systemd.network.networks.${name}.cakeConfig.Bandwidth = bandwidth;
    };
  }
