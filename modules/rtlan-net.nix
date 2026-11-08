{ wat, ... }:
{
  flake.nixosModules.rtlan-net = wat.mkModuleWrapped [ "rtlan-net" ] (
    {
      cfg,
      config,
      lib,
      ...
    }:
    with lib;

    {

      wat.thelegy.wg-net.rtlan = {
        privateKeyFile = config.sops.secrets.wgPrivateKey.path;
        defaultPort = 1333;
      };

      systemd.services.systemd-networkd.serviceConfig.SupplementaryGroups = [ "keys" ];

      sops.secrets.wgPrivateKey = {
        format = "yaml";
        group = "systemd-network";
        mode = "0640";
      };

      networking.firewall.allowedUDPPorts = [ 1333 ];

      networking.nftables.firewall = {
        zones.rtlan = {
          interfaces = [ "rtlan" ];
        };
      };

    }

  );
}
