{
  mkTrivialModule,
  config,
  ...
}:
let
  dir = "/srv/audiobooks";
  domain = "audiobooks.beinke.cloud";
  group = config.services.audiobookshelf.group;
  port = 45425;
  user = config.services.audiobookshelf.user;
in
mkTrivialModule {
  systemd.tmpfiles.rules = [ "d ${dir} 0700 ${user} ${group}" ];

  services.audiobookshelf = {
    enable = true;
    port = port;
  };

  wat.thelegy.traefik.dynamicConfigs.audiobookshelf = {
    http.services.audiobookshelf.loadBalancer = {
      servers = [ { url = "http://127.0.0.1:${toString port}"; } ];
    };
    http.routers.audiobookshelf = {
      rule = "Host(`${domain}`)";
      service = "audiobookshelf";
    };
  };
}
