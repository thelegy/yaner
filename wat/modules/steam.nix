{
  mkTrivialModule,
  config,
  lib,
  options,
  pkgs,
  ...
}:

mkTrivialModule {

  wat.thelegy.desktop.enable = true;

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "steam"
      "steam-original"
      "steam-runtime"
    ];

  nixpkgs.config.packageOverrides = pkgs: {
    steam = pkgs.steam.override {
      extraPkgs =
        pkgs: with pkgs; [
          cabextract
          keyutils
          libbsd
          libkrb5
          mesa-demos
          openssl
          phinger-cursors
        ];
    };
  };

  users.users.beinke = {
    packages = with pkgs; [
      gamescope
      protonup-ng
      protontricks
      steam
      steam.run
    ];
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
  };

}
