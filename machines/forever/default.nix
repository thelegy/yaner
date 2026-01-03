{ mkMachine, ... }:

mkMachine { } (
  {
    lib,
    config,
    options,
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
    wat.thelegy.matrix = {
      enable = true;
      sopsSecretsFile = "matrix-synapse-keys";
    };
    wat.thelegy.postgresql.package = pkgs.postgresql_14;
    wat.thelegy.traefik.enable = true;
    wat.thelegy.traefik.dnsProvider = "desec";
    wat.thelegy.traefik.dynamicConfigs.ingress = {
      tcp.services.ingress.loadBalancer = {
        servers = [ { address = "192.168.5.37:33030"; } ];
        proxyProtocol.version = 2;
      };
      tcp.routers.ingress = {
        rule = lib.concatMapStringsSep " || " (x: "HostSNI(`${x}`)") [
          "audiobooks.beinke.cloud"
          "docs.sibylle.beinke.cloud"
          "ha.0jb.de"
        ];
        tls.passthrough = true;
        entryPoints = [ "websecure" ];
        service = "ingress";
      };
    };

    wat.thelegy.vaultwarden = {
      enable = true;
      sopsSecretsFile = "vaultwarden";
    };

    wat.thelegy.static-net.enable = true;
    systemd.network.networks.static.routes = [
      {
        Destination = "192.168.5.0/24";
        Gateway = "192.168.242.4";
      }
    ];

    networking.nftables.firewall.rules.nixos-firewall.enable = false;
    networking.nftables.firewall.rules.public-services = {
      from = "all";
      to = [ "fw" ];
      allowedTCPPorts = [
        80
        443
      ];
    };

    services.traefik.staticConfigOptions = {
      entryPoints.websecure_pp = {
        address = "192.168.242.1:33030";
        asDefault = true;
        http.tls.certResolver = "letsencrypt";
        proxyProtocol.trustedIPs = [ "192.168.5.0/24" ];
      };
    };
    networking.nftables.firewall.rules."traefik_pp" = {
      from = [ "static" ];
      to = [ "fw" ];
      allowedTCPPorts = [ 33030 ];
    };

    networking.nftables.firewall.zones.static-interface.interfaces = [ "static" ];
    networking.nftables.firewall.zones.ingress-home = {
      parent = "static-interface";
      ipv4Addresses = [ "192.168.242.4" ];
    };
  }
)
