{ mkMachine, ... }:

mkMachine { } (
  { lib, config, ... }:
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
        "bruchstr.0jb.de"
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

    systemd.network.netdevs.bruchstr = {
      netdevConfig.Name = "bruchstr";
      netdevConfig.Kind = "wireguard";
      wireguardConfig.PrivateKeyFile = config.sops.secrets.wgPrivateKey.path;
      wireguardConfig.ListenPort = 51820;
      wireguardPeers = [
        {
          PublicKey = "I/2RY0P3bSNjeUZ/R/o6UE8JiRQIn6D7bMR0DyoEOGE=";
          AllowedIPs = "192.168.241.57/32";
        }
      ];
    };

    systemd.network.networks.bruchstr = {
      name = "bruchstr";
      address = [ "192.168.241.58/30" ];
    };

    networking.nftables.firewall.rules.bruchstr = {
      from = "all";
      to = [ "fw" ];
      allowedUDPPorts = [
        config.systemd.network.netdevs.bruchstr.wireguardConfig.ListenPort
      ];
    };

    services.nginx.virtualHosts."bruchstr.0jb.de" = {
      useACMEHost = config.networking.fqdn;
      forceSSL = true;
      locations."/" = {
        recommendedProxySettings = true;
        proxyWebsockets = true;
        proxyPass = "http://192.168.241.57:8123";
        extraConfig = ''
          client_max_body_size 100M;
        '';
      };
    };

  }
)
