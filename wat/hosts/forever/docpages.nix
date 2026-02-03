{ config, ... }:

{

  services.nginx.virtualHosts.main = {
    serverAliases = [
      "0jb.de"
    ];
    locations."/".root = "/srv/www/0jb.de";
    locations."~ ^/akhm(/|$)".extraConfig = ''
      rewrite ^/akhm(.*)$ https://github.com/thelegy/analog-keyboard-handwiring-module$1 redirect;
    '';
  };

  legy.docpages = {
    target_dir = "/srv/www/0jb.de";
    pages = {
      "Qfrl".flake = "gitlab:beini/things?host=git.c3pb.de#docpages.Qfrl";
      #"BuzzLight".flake = "gitlab:beini/things?dir=BuzzLight/BuzzLight&host=git.c3pb.de";
    };
  };

}
