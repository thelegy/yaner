{mkMachine, ...}:
mkMachine {} ({
  lib,
  config,
  pkgs,
  ...
}: {
  system.stateVersion = "23.11";

  wat.installer.hcloud = {
    enable = true;
    macAddress = "96:00:02:e0:84:a5";
    ipv4Address = "168.119.120.247/32";
    ipv6Address = "2a01:4f8:1c1b:8836::1/64";
  };

  wat.thelegy.base.enable = true;

  wat.thelegy.syncthing.enable = true;
  services.syncthing.guiAddress = "[::]:8384";
  networking.nftables.firewall.rules.syncthing = {
    from = ["tailscale"];
    to = ["fw"];
    allowedTCPPorts = [8384];
  };

  services.openssh.settings.X11Forwarding = true;

  virtualisation.vswitch.enable = true;
  environment.extraInit = ''
    export LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib/
  '';
  environment.systemPackages = [
    pkgs.mininet
    config.virtualisation.vswitch.package
    pkgs.xterm
    pkgs.iperf
    (pkgs.python310.withPackages (p: [
      p.greenlet
      p.pip
    ]))
    pkgs.entr
    pkgs.traceroute
    pkgs.mtr
  ];
})
