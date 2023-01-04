{ mkMachine, flakes, ... }:

mkMachine {
  nixpkgs = flakes.nixpkgs-snm;
} ({ lib, pkgs, config, ... }: with lib; {

  system.stateVersion = "22.11";

  imports = [
    flakes.snm.nixosModule
  ];

  wat.installer.hcloud = {
    enable = true;
    macAddress = "96:00:00:33:c3:1e";
    ipv4Address = "78.47.82.136/32";
    ipv6Address = "2a01:4f8:c2c:e7b1::/64";
  };

  wat.thelegy.backup.enable = true;
  wat.thelegy.base.enable = true;
  wat.thelegy.firewall.enable = true;
  wat.thelegy.monitoring.enable = true;

})
