{ mkTrivialModule
, lib
, pkgs
, ...
}: with lib;

let
  hostName = "grocy.0jb.de";
in mkTrivialModule {

  services.grocy = {
    enable = true;
    hostName = hostName;
    nginx.enableSSL = false;
    settings = {
      currency = "EUR";
      culture = "de";
      calendar.firstDayOfWeek = 1;  # Monday
    };
  };

  services.nginx.virtualHosts.${hostName} = {
    forceSSL = true;
    sslCertificate = "/var/lib/acme/home.0jb.de/fullchain.pem";
    sslCertificateKey = "/var/lib/acme/home.0jb.de/key.pem";
  };

}
