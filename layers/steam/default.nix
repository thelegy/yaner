{ config, options, pkgs, ... }:

{

  nixpkgs.config.allowUnfree = true;

  hardware.steam-hardware.enable = true;
  hardware.opengl = {
    driSupport = true;
    driSupport32Bit = true;
  };
  hardware.pulseaudio.support32Bit = true;

  users.users.beinke = {
    packages = with pkgs; [
      steam
    ];
  };

}
