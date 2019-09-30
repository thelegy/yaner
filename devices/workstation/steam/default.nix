{ config, options, pkgs, ... }:

{

  nixpkgs.config.allowUnfree = true;

  hardware.steam-hardware.enable = true;
  hardware.opengl.driSupport32Bit = true;

  users.users.beinke = {
    packages = with pkgs; [
      steam
    ];
  };

}
