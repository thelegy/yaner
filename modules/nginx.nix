{
  mkModule,
  config,
  lib,
  liftToNamespace,
  ...
}:
with lib;

mkModule {
  options =
    cfg:
    liftToNamespace {

      useACMEHost = mkOption {
        type = types.str;
        default = config.networking.fqdn;
      };

    };
  config = cfg: {

    wat.thelegy.acme.reloadUnits = [
      "nginx.service"
    ];

    services.nginx = {
      enable = true;
      virtualHosts.default = {
        default = true;
        addSSL = true;
        useACMEHost = cfg.useACMEHost;
        locations."/".return = "404";
      };
      virtualHosts.main = {
        serverName = config.networking.fqdn;
        forceSSL = true;
        useACMEHost = cfg.useACMEHost;
        locations."/" = mkDefault { return = "404"; };
      };
    };

    users.users.nginx.extraGroups = [ "acme" ];

    networking.nftables.firewall.rules.nginx = {
      from = mkDefault "all";
      to = [ "fw" ];
      allowedTCPPorts = mkDefault [
        80
        443
      ];
    };

  };
}
