{

  description = "Yet Another Nix Expression Repository";


  inputs = {

    nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;

    wat = {
      url = github:thelegy/wat;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = github:Mic92/sops-nix;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    homemanager = {
      url = github:nix-community/home-manager;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-nftables-firewall = {
      url = github:thelegy/nixos-nftables-firewall;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    queezle-dotfiles = {
      url = gitlab:jens/dotfiles?host=git.c3pb.de;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    qed.url = github:thelegy/qed/dev;

    qbar.url = gitlab:jens/qbar?host=git.c3pb.de;

    nixGL = {
      url = github:guibou/nixGL;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-stable.url = github:NixOS/nixpkgs/nixos-23.05;

    nixpkgs-staging-next.url = github:NixOS/nixpkgs/staging-next;

    nixpkgs-roborock.url = github:NixOS/nixpkgs/b573a7f69484a7d213680abb70b4f95bdc28eee5;

    nixpkgs-snm = {
      url = github:NixOS/nixpkgs/nixos-21.11;
      follows = "snm/nixpkgs-22_11";
    };
    snm = {
      url = gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-22.11;
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };


  outputs = flakes@{ wat, ... }: wat.lib.mkWatRepo flakes (
    { findModules
    , findMachines
    , ...
    }: rec {
      namespace = [ "thelegy" ];
      loadOverlays = [
        flakes.nixGL.overlays.default
        flakes.queezle-dotfiles.overlay
      ];
      loadModules = [
        flakes.homemanager.nixosModules.home-manager
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
