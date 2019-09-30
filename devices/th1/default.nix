{ config, options, pkgs, ... }:

{

  imports = [
    ./hardware-configuration.nix
    ../workstation
  ];


  # Fix the LTE modem not being detected
  systemd.services."network-manager".requires = [ "modem-manager.service" ];

  users.users.beinke.packages = with pkgs; [
    bc  # For my battery script i use for my sway bar
  ];

  hardware.cpu.intel.updateMicrocode = true;

  services.illum.enable = true;

  networking.hostName = "th1";

  system.stateVersion = "19.03";

}
