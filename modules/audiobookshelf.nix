{
  mkTrivialModule,
  lib,
  config,
  pkgs,
  ...
}:
let
  acmeHost = config.networking.fqdn;
  dir = "/srv/audiobooks";
  domain = "audiobooks.beinke.cloud";
  group = config.services.audiobookshelf.group;
  port = 45425;
  user = config.services.audiobookshelf.user;
in
mkTrivialModule {
  wat.thelegy.acme.extraDomainNames = [ domain ];

  systemd.tmpfiles.rules = [ "d ${dir} 0700 ${user} ${group}" ];

  services.audiobookshelf = {
    enable = true;
    port = port;
  };

  services.nginx.virtualHosts.${domain} = {
    forceSSL = true;
    useACMEHost = acmeHost;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString port}";
      recommendedProxySettings = true;
      proxyWebsockets = true;
    };
  };
}
