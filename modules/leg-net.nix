{ mkTrivialModule
, config
, lib
, ...
}: with lib;

mkTrivialModule {

  wat.thelegy.wg-net.leg = {
    privateKeyFile = config.sops.secrets.wgPrivateKey.path;
    defaultPort = 1347;
  };

  systemd.services.systemd-networkd.serviceConfig.SupplementaryGroups = [ "keys" ];

  sops.secrets.wgPrivateKey = {
    format = "yaml";
    group = "systemd-network";
    mode = "0640";
  };

}
