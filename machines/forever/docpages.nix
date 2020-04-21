{ ... }:

{

  services.nginx.virtualHosts."0jb.de" = {
    useACMEHost = "forever.0jb.de";
    forceSSL = true;
    root = "/srv/www/0jb.de";
  };

  legy.docpages = {
    target_dir = "/srv/www/0jb.de";
    pages = {
      "Qfrl".repo = "https://git.c3pb.de/beini/things.git";
    };
  };

}
