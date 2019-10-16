{ config, options, pkgs, ... }:

{

  imports = [
    ../workstation
    ../amnesia
  ];

  # Enable brightness switches
  services.illum.enable = true;

}
