{ config, options, pkgs, ... }:

{

  hardware.pulseaudio.enable = true;

  environment.systemPackages = with pkgs; [
    pamixer
  ];

}