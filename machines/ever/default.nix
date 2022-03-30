{ mkMachine, ...}:

mkMachine {} ({ pkgs, ... }:
{

  imports = [
    ./hardware-configuration.nix
    ./borg-server.nix
    ./docpages.nix
  ];

  wat.thelegy.base.enable = true;
  wat.thelegy.backup.enable = true;
  wat.thelegy.matrix = {
    enable = true;
    useACMEHost = "ever.0jb.de";
    secretsFile = "/etc/secrets/matrix-synapse.yml";
  };

  boot.loader.grub.configurationLimit = 3;
  boot.loader.grub.device = "/dev/sda";
  boot.initrd.luks.devices.local_disk = {
    device = "/dev/sda3";
  };

  boot.initrd.preDeviceCommands = "(while sleep 1; do echo DUMMY_PASSWORD | cryptsetup-askpass; done)&";

  networking.useDHCP = false;
  systemd.network = {
    enable = true;
    networks.default = {
      matchConfig.MACAddress = "96:00:00:33:c3:1e";
      address = [ "2a01:4f8:c2c:e7b1::1/64" ];
      dns = [
        "213.133.98.98"
        "213.133.99.99"
        "213.133.100.100"
      ];
      gateway = [
        "172.31.1.1"
        "fe80::1"
      ];
      addresses = [{
        addressConfig = {
          Address = "78.47.82.136/32";
          Peer = "172.31.1.1";
        };
      }];
    };
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];


  services.nginx = {
    enable = true;
    virtualHosts.default = {
      default = true;
      useACMEHost = "ever.0jb.de";
      forceSSL = true;
    };
  };

  security.acme = {
    acceptTerms = true;
    #server = "https://acme-staging-v02.api.letsencrypt.org/directory";
    defaults.email = "mail+letsencrypt@0jb.de";
    preliminarySelfsigned = false;
    certs = {
      "ever.0jb.de" = {
        extraDomainNames = [
          "0jb.de"
          "element.0jb.de"
          "matrix.0jb.de"
        ];
        dnsProvider = "hurricane";
        credentialsFile = "/etc/secrets/acme";
        group = "nginx";
        postRun = ''
          systemctl start --failed nginx.service
          systemctl reload nginx.service
        '';
      };
    };
  };

  system.stateVersion = "19.09";

})
