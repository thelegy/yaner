{ config, options, pkgs, ... }:

{

  imports = [
    ./hardware-configuration.nix
    ../../layers/laptop
  ];


  # Fix the LTE modem not being detected
  systemd.services."network-manager".requires = [ "modem-manager.service" ];

  users.users.beinke.packages = with pkgs; [
    bc  # For my battery script i use for my sway bar
  ];

  hardware.cpu.intel.updateMicrocode = true;

  system.stateVersion = "19.03";

}
