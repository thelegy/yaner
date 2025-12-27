{

  description = "Yet Another Nix Expression Repository";

  inputs = {

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    wat = {
      url = "github:thelegy/wat";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    homemanager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-nftables-firewall = {
      url = "github:thelegy/nixos-nftables-firewall";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    qed.url = "github:thelegy/qed/dev";

    qbar.url = "gitlab:jens/qbar?host=git.c3pb.de";

    nixGL = {
      url = "github:guibou/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";

    nixpkgs-snm.url = "github:NixOS/nixpkgs/nixos-25.11";
    snm = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-25.11";
      inputs.nixpkgs.follows = "nixpkgs-snm";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dankMaterialShell = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    flakes@{ wat, ... }:
    wat.lib.mkWatRepo flakes (
      {
        findModules,
        findMachines,
        ...
      }:
      rec {
        namespace = [ "thelegy" ];
        loadOverlays = [
          flakes.nix-index-database.overlays.nix-index
          flakes.nixGL.overlays.default
        ];
        loadModules = [
          flakes.homemanager.nixosModules.home-manager
          flakes.nix-index-database.nixosModules.nix-index
          flakes.nixos-nftables-firewall.nixosModules.default
          flakes.sops-nix.nixosModules.sops
        ];
        outputs = {

          overlay = import ./pkgs flakes;

          nixosModules = findModules namespace ./modules;

          nixosConfigurations = findMachines ./machines;

          packages = wat.lib.withPkgsForLinux flakes.nixpkgs [ flakes.self.overlay ] (pkgs: {

          });

        };
      }
    );

}
