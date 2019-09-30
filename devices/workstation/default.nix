{ config, options, pkgs, ... }:

{

  imports = [
    ../desktop
  ];

  nixpkgs.config.allowUnfree = true;

  users.users.beinke = {
    packages = with pkgs; [
      vscode
      signal-desktop
      tdesktop
      thunderbird
      steam
      stack
    ];
  };

  hardware.steam-hardware.enable = true;

}
