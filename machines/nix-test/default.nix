{ mkMachine, ... }:

mkMachine {} ({ lib, config, ... }: with lib; {

  wat.installer.hcloud = {
    enable = true;
    macAddress = "96:00:00:f4:0a:5e";
    ipv4Address = "95.216.217.52/32";
    ipv6Address = "2a01:4f9:c011:470c::/64";
  };

  wat.thelegy.base.enable = true;
  wat.thelegy.firewall.enable = true;

  networking.services.yggdrasil-tcp = 42042;
  services.yggdrasil = {
    enable = true;
    config = {
      Listen = [
        "tcp://0.0.0.0:${toString config.networking.services.yggdrasil-tcp.port}"
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
      ingressExpression = "ip6 saddr {203:4a69:1559:3f0:3933:4f27:d573:9ef8}";
      egressExpression = "ip6 daddr {203:4a69:1559:3f0:3933:4f27:d573:9ef8}";
    };
    rules.yggdrasil = {
      from = "all";
      to = [ "fw" ];
      allowedServices = [
        "yggdrasil-tcp"
      ];
    };
    rules.home-services = {
      from = [ "ygg-home" ];
      to = [ "fw" ];
      allowedServices = [
        #"http"
      ];
    };
  };

  services.nginx.enable = true;

})
