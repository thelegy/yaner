{ config, ... }:

{

  services.nginx.virtualHosts.main = {
    serverAliases = [
      "0jb.de"
    ];
    root = "/srv/www/0jb.de";
  };

  legy.docpages = {
    target_dir = "/srv/www/0jb.de";
    pages = {
      "Qfrl".flake = "gitlab:beini/things?host=git.c3pb.de#docpages.Qfrl";
      #"BuzzLight".flake = "gitlab:beini/things?dir=BuzzLight/BuzzLight&host=git.c3pb.de";
    };
  };

}
