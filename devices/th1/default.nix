{ config, options, pkgs, ... }:

{

  imports = [
    ./hardware-configuration.nix
    ../desktop
  ];


  # Fix the LTE modem not being detected
  systemd.services."network-manager".requires = [ "modem-manager.service" ];

  users.users.beinke.packages = with pkgs; [
    bc  # For my battery script i use for my sway bar
  ];

  networking.hostName = "th1";

}
