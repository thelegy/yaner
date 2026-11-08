{ wat, ... }:
{
  flake.nixosModules.steam = wat.mkModuleWrapped [ "steam" ] (
    {
      cfg,
      config,
      lib,
      options,
      pkgs,
      ...
    }:

    {

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
          extraPkgs = pkgs: [
            pkgs.cabextract
            pkgs.keyutils
            pkgs.libbsd
            pkgs.libkrb5
            pkgs.mesa-demos
            pkgs.openssl
            pkgs.phinger-cursors
          ];
        };
      };

      users.users.beinke = {
        packages = [
          pkgs.gamescope
          pkgs.protonup-ng
          pkgs.protontricks
          pkgs.steam
          pkgs.steam.run
        ];
      };

      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
      };

    }

  );
}
