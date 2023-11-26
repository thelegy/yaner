{ mkMachine, ... }:

mkMachine {} ({ lib, config, ... }: with lib; {

  imports = [
    ./borg-server.nix
    ./docpages.nix
  ];

  wat.installer.hcloud = {
    enable = true;
    macAddress = "96:00:01:2f:d3:ce";
    ipv4Address = "195.201.216.243/32";
    ipv6Address = "2a01:4f8:1c1e:8ee7::1/64";
  };

  wat.thelegy.acme = {
    enable = true;
    staging = false;
    extraDomainNames = [
      "0jb.de"
      "element.0jb.de"
      "matrix.0jb.de"
      "mailmetrics.0jb.de"
      "pw.0jb.de"
    ];
  };
  wat.thelegy.base.enable = true;
  wat.thelegy.backup.enable = true;
  wat.thelegy.dfhq-mc.enable = true;
  wat.thelegy.firewall.enable = true;
  wat.thelegy.nginx.enable = true;
  wat.thelegy.matrix = {
    enable = true;
    useACMEHost = "forever.0jb.de";
    sopsSecretsFile = "matrix-synapse-keys";
  };
  wat.thelegy.monitoring.enable = true;
  wat.thelegy.vaultwarden = {
    enable = true;
    useACMEHost = "forever.0jb.de";
    sopsSecretsFile = "vaultwarden";
  };


  networking.nftables.firewall = {
    rules.nixos-firewall.enable = false;
    rules.public-services = {
      from = "all";
      to = [ "fw" ];
      allowedTCPPorts = [
        80
        443
      ];
    };
  };

  system.stateVersion = "22.05";

})
