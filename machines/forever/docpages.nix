{ config, ... }:

{

  services.nginx.virtualHosts.main = {
    serverName = "${config.networking.hostName}.0jb.de";
    serverAliases = [
      "0jb.de"
    ];
    useACMEHost = "forever.0jb.de";
    forceSSL = true;
    root = "/srv/www/0jb.de";
  };

  legy.docpages = {
    target_dir = "/srv/www/0jb.de";
    pages = {
      "Qfrl".flake = "gitlab:beini/things?host=git.c3pb.de#docpages.Qfrl";
      "BuzzLight".flake = "gitlab:beini/things?dir=BuzzLight/BuzzLight&host=git.c3pb.de";
    };
  };

}
