{
  mkTrivialModule,
  config,
  lib,
  ...
}:
with lib;
  mkTrivialModule {
    wat.thelegy.wg-net.static = {
      privateKeyFile = config.sops.secrets.wgPrivateKey.path;
      defaultPort = 1334;
    };

    systemd.services.systemd-networkd.serviceConfig.SupplementaryGroups = ["keys"];

    sops.secrets.wgPrivateKey = {
      format = "yaml";
      group = "systemd-network";
      mode = "0640";
    };

    networking.nftables.firewall = {
      zones.static-range.ipv4Addresses = ["192.168.242.0/24"];
      zones.static.interfaces = ["static"];
      rules.static-spoofing = {
        from = ["static-range"];
        to = "all";
        extraLines = [
          "iifname \"static\" return"
          "counter drop"
        ];
      };
      rules.static-transport = {
        from = "all";
        to = ["fw"];
        allowedUDPPorts = [1334];
      };
    };
  }
