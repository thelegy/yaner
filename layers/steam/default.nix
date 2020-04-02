{ config, options, pkgs, ... }:

let

  steam = pkgs.steam.override {
    extraPkgs = pkgs: with pkgs; [
      libbsd
    ];
    nativeOnly = true;
  };

in {

  nixpkgs.config.allowUnfree = true;

  hardware.steam-hardware.enable = true;
  hardware.opengl = {
    driSupport = true;
    driSupport32Bit = true;
  };
  hardware.pulseaudio.support32Bit = true;

  users.users.beinke = {
    packages = [
      pkgs.steam
      steam.run
    ];
  };

}
