{ config, options, pkgs, ... }:

{

  imports = [
    ../workstation
  ];

  # Enable brightness switches
  services.illum.enable = true;

}
