{ config, options, pkgs, ... }:

{

  imports = [
    ../desktop
    ../steam
  ];

  nixpkgs.config.allowUnfree = true;

  users.users.beinke = {
    packages = with pkgs; [
      all-hies-latest
      direnv
      signal-desktop
      stack
      tdesktop
      thunderbird
      vscode
    ];
  };

}
