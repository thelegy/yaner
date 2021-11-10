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

  boot.loader.grub.configurationLimit = 3;
  boot.loader.grub.device = "/dev/sda";
  boot.initrd.luks.devices.local_disk = {
    device = "/dev/sda3";
  };

  boot.initrd.preDeviceCommands = "(while sleep 1; do echo DUMMY_PASSWORD | cryptsetup-askpass; done)&";


  networking.useDHCP = false;
  networking.interfaces.ens3 = {
    useDHCP = true;
    ipv6.addresses = [ { address = "2a01:4f8:c2c:e7b1::1"; prefixLength = 64; } ];
  };
  networking.interfaces.ens10.useDHCP = true;
  networking.defaultGateway6 = { address = "fe80::1"; interface = "ens3"; };


  networking.firewall.allowedTCPPorts = [
    80
    443
  ];


  services.nginx = {
    enable = true;
    virtualHosts.default = {
      default = true;
      useACMEHost = "forever.0jb.de";
      forceSSL = true;
    };
  };

  security.acme = {
    acceptTerms = true;
    #server = "https://acme-staging-v02.api.letsencrypt.org/directory";
    email = "mail+letsencrypt@0jb.de";
    preliminarySelfsigned = false;
    certs = {
      "forever.0jb.de" = {
        extraDomainNames = [
          "0jb.de"
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
