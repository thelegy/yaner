{ mkTrivialModule
, lib
, pkgs
, ...
}: with lib;

let
  hostname = "mc.dfhq.dedyn.io";
  mc_port = 25565;
  voice_port = 24454;
in
mkTrivialModule {

  networking.nftables.firewall = {
    rules.dfhq-mc = {
      from = "all";
      to = [ "fw" ];
      allowedTCPPorts = [ mc_port ];
      allowedUDPPorts = [ voice_port ];
    };
  };

  services.nginx.appendConfig = ''
    stream {
      server {
        listen ${toString mc_port};
        proxy_pass ${hostname}:${toString mc_port};
      }
      server {
        listen ${toString voice_port} udp;
        proxy_pass ${hostname}:${toString voice_port};
      }
    }
  '';

}
