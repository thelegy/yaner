{ config, lib, options, pkgs, ... }:

{

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "steam"
    "steam-original"
    "steam-runtime"
  ];

  nixpkgs.config.packageOverrides = pkgs: {
    steam = pkgs.steam.override {
      extraPkgs = pkgs: with pkgs; [
        cabextract
        glxinfo
        libbsd
      ];
    };
  };

  users.users.beinke = {
    packages = with pkgs; [
      steam
      steam.run
      protonup
    ];
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
  };

}
