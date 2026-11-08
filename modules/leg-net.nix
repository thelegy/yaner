{ wat, ... }:
{
  flake.nixosModules.leg-net = wat.mkModuleWrapped [ "leg-net" ] (
    {
      cfg,
      config,
      lib,
      ...
    }:
    with lib;

    {

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

  );
}
