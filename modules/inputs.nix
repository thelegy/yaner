{ ... }:
{
  flake-file.inputs = {

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    homemanager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-nftables-firewall.url = "github:thelegy/nixos-nftables-firewall/dev";

    qed.url = "github:thelegy/qed/tmp";

    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";

    nixpkgs-snm.url = "github:NixOS/nixpkgs/nixos-26.05";
    snm = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-26.05";
      inputs.nixpkgs.follows = "nixpkgs-snm";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms-plugin-registry = {
      url = "github:AvengeMedia/dms-plugin-registry";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    systems.url = "github:nix-systems/default";

    nixwrap = {
      url = "github:rti/nixwrap";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };

  };
}
