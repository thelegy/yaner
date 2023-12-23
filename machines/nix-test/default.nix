{ mkMachine, ... }:

mkMachine {} ({ lib, config, ... }: with lib; let
  yggdrasil-port = 42042;
in {

  wat.installer.hcloud = {
    enable = true;
    macAddress = "96:00:00:f4:0a:5e";
    ipv4Address = "95.216.217.52/32";
    ipv6Address = "2a01:4f9:c011:470c::/64";
  };

  wat.thelegy.base.enable = true;
  wat.thelegy.firewall.enable = true;

  services.yggdrasil = {
    enable = true;
    config = {
      Listen = [
        "tcp://0.0.0.0:${toString yggdrasil-port}"
      ];
      IfName = "ygg";
    };
  };
  networking.nftables.firewall = {
    zones.ygg = {
      interfaces = [ "ygg" ];
    };
    zones.ygg-home = {
      parent = "ygg";
      ipv6Addresses = [ "203:4a69:1559:3f0:3933:4f27:d573:9ef8" ];
    };
    rules.yggdrasil = {
      from = "all";
      to = [ "fw" ];
      allowedTCPPorts = [
        yggdrasil-port
      ];
    };
  };

  services.nginx.enable = true;

})
