{ config, options, pkgs, ... }:

{

  imports = [
    ../desktop
    ./steam
  ];

  nixpkgs.config.allowUnfree = true;

  users.users.beinke = {
    packages = with pkgs; [
      vscode
      signal-desktop
      tdesktop
      thunderbird
      stack
      all-hies-latest
    ];
  };

}
