{ mkMachine, ... }:

mkMachine { } (
  {
    lib,
    config,
    pkgs,
    ...
  }:
  with lib;
  {

    system.stateVersion = "22.05";

    imports = [
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
        "pw.beinke.cloud"
      ];
      dnsProvider = "desec";
    };
    wat.thelegy.base.enable = true;
    wat.thelegy.backup = {
      enable = true;
      borgbaseRepo = "dlj1no3s";
    };
    wat.thelegy.crowdsec.enable = true;
    wat.thelegy.crowdsec-lapi.enable = true;
    wat.thelegy.dfhq-mc.enable = true;
    wat.thelegy.nginx.enable = true;
    wat.thelegy.matrix = {
      enable = true;
      useACMEHost = "forever.0jb.de";
      sopsSecretsFile = "matrix-synapse-keys";
    };
    wat.thelegy.postgresql.package = pkgs.postgresql_14;
    wat.thelegy.vaultwarden = {
      enable = true;
      useACMEHost = "forever.0jb.de";
      sopsSecretsFile = "vaultwarden";
    };

    wat.thelegy.static-net.enable = true;
    wat.thelegy.remote-ip-y = {
      enable = true;
      role = "proxy";
    };

    networking.nftables.firewall.rules.nixos-firewall.enable = false;
    networking.nftables.firewall.rules.public-services = {
      from = "all";
      to = [ "fw" ];
      allowedTCPPorts = [
        80
        443
      ];
    };

    systemd.network.networks.default.addresses = [
      {
        Address = "94.130.190.66/32";
        Peer = "172.31.1.1";
      }
    ];

    boot.kernel.sysctl."net.ipv4.ip_forward" = "1";
    networking.nftables.requiredChains = [
      "nat_input"
      "nat_output"
      "nat_prerouting"
      "nat_postrouting"
    ];
    networking.nftables.firewall.zones.static-interface.interfaces = [ "static" ];
    networking.nftables.firewall.zones.ingress-home = {
      parent = "static-interface";
      ipv4Addresses = [ "192.168.242.4" ];
    };
    networking.nftables.chains =
      let
        hookRule = hook: {
          after = mkForce [ "start" ];
          before = mkForce [ "veryEarly" ];
          rules = singleton hook;
        };
      in
      {
        nat_prerouting = {
          hook = hookRule "type nat hook prerouting priority dstnat;";
          ingress-home.rules = [
            "ip daddr 94.130.190.66 dnat to 192.168.242.4"
          ];
        };
        nat_output = {
          hook = hookRule "type nat hook output priority dstnat";
          ingress-home-hairpin.rules = [
            "ip daddr 94.130.190.66 ct mark set 0x00000001 dnat ip to 192.168.242.4"
          ];
        };
        nat_postrouting = {
          hook = hookRule "type nat hook postrouting priority srcnat";
          ingress-home-hairpin.rules = [
            "ct mark 0x00000001 snat ip to 94.130.190.66"
          ];
        };
      };
    networking.nftables.firewall.rules."ingress-home" = {
      from = "all";
      to = [ "ingress-home" ];
      allowedTCPPorts = [
        80
        443
      ];
      allowedUDPPorts = [
        443
      ];
    };

  }
)
