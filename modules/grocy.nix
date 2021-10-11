{ mkTrivialModule
, lib
, pkgs
, ...
}: with lib;

let
  hostName = "grocy.localhost";
  ip = "127.0.0.42";
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

  networking.hosts."${ip}" = [ hostName ];

  services.nginx.virtualHosts = {
    "${hostName}" = {
      listen = [{
        addr = ip;
      }];
    };
    default = {
      locations."/grocy/" = {
        proxyPass = "http://${hostName}/";
        extraConfig = ''
          sub_filter "http://${hostName}/" "http://$host/grocy/";
          sub_filter "https://${hostName}/" "https://$host/grocy/";
          sub_filter_once off;
        '';
      };
    };
  };

}
