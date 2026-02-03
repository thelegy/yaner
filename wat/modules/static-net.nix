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
    nodes.ucg-pb = {
      address = "192.168.242.4/24";
      allowedIPs = [
        "192.168.242.4/32"
        "192.168.5.0/24"
      ];
      publicKey = "Dzd1Qa8Deo9HJy5WXNexmvErkTDDbnEuZ+VjUdFbZWc=";
    };
  };

  systemd.services.systemd-networkd.serviceConfig.SupplementaryGroups = [ "keys" ];

  sops.secrets.wgPrivateKey = {
    format = "yaml";
    group = "systemd-network";
    mode = "0640";
  };

  networking.nftables.firewall = {
    zones.static-range.ipv4Addresses = [ "192.168.242.0/24" ];
    zones.static.interfaces = [ "static" ];
    rules.static-spoofing = {
      from = [ "static-range" ];
      to = "all";
      extraLines = [
        "iifname \"static\" return"
        "counter drop"
      ];
    };
    rules.static-transport = {
      from = "all";
      to = [ "fw" ];
      allowedUDPPorts = [ 1334 ];
    };
  };
}
