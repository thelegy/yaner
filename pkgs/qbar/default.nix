{ pkgs ? import <nixpkgs> {}
, fetchgit ? pkgs.fetchgit
, haskellPackages ? pkgs.haskellPackages
, callCabal2nix ? haskellPackages.haskellPackages
}:

let
  qbar-repo-def = with builtins; fromJSON (readFile ./repo.json);
  qbar-repo = fetchgit {
    inherit (qbar-repo-def) url rev sha256 ;
  };
in
haskellPackages.callCabal2nix "qbar" qbar-repo {}
