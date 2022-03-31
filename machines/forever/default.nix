{ mkMachine, ... }:

mkMachine {} ({ lib, config, ... }: with lib; {

  imports = [
    ./docpages.nix
  ];

  wat.installer.hcloud = {
    enable = true;
    macAddress = "96:00:01:2f:d3:ce";
    ipv4Address = "195.201.216.243/32";
    ipv6Address = "2a01:4f8:1c1e:8ee7::1/64";
  };

  wat.thelegy.base.enable = true;
  wat.thelegy.firewall.enable = true;


  networking.nftables.firewall = {
    rules.public-services = {
      from = "all";
      to = [ "fw" ];
      allowedServices = [
        "http"
        "https"
      ];
    };
  };

  security.acme = {
    acceptTerms = true;
    #server = "https://acme-staging-v02.api.letsencrypt.org/directory";
    defaults.email = "mail+letsencrypt@0jb.de";
    preliminarySelfsigned = false;
    certs = {
      "forever.0jb.de" = {
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

  services.nginx = {
    enable = true;
    virtualHosts.default = {
      default = true;
      useACMEHost = "forever.0jb.de";
      forceSSL = true;
    };
  };

})
