# DO-NOT-EDIT. This file was auto-generated using github:vic/flake-file.
# Use `nix run .#write-flake` to regenerate it.
{

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);

  inputs = {
    dankMaterialShell = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:AvengeMedia/DankMaterialShell";
    };
    flake-file.url = "github:vic/flake-file";
    flake-parts = {
      inputs.nixpkgs-lib.follows = "nixpkgs-lib";
      url = "github:hercules-ci/flake-parts";
    };
    homemanager = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/home-manager";
    };
    import-tree.url = "github:vic/import-tree";
    nix-index-database = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/nix-index-database";
    };
    nixos-nftables-firewall = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:thelegy/nixos-nftables-firewall";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-lib.follows = "nixpkgs";
    nixpkgs-snm.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";
    qbar.url = "gitlab:jens/qbar?host=git.c3pb.de";
    qed.url = "github:thelegy/qed/dev";
    snm = {
      inputs.nixpkgs.follows = "nixpkgs-snm";
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-25.11";
    };
    sops-nix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:Mic92/sops-nix";
    };
    systems.url = "github:nix-systems/default";
    wat = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:thelegy/wat/dendritic";
    };
  };

}
