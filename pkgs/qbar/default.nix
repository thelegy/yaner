{ pkgs ? import <nixpkgs> {}
, fetchgit ? pkgs.fetchgit
, haskellPackages ? pkgs.haskellPackages
, callCabal2nix ? haskellPackages.callCabal2nix
}:

let
  qbar-repo-def = with builtins; fromJSON (readFile ./repo.json);
  qbar-repo = fetchgit {
    inherit (qbar-repo-def) url rev sha256 ;
  };
in
callCabal2nix "qbar" qbar-repo {}
