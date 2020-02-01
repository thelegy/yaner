let pkgs = import <nixpkgs> {}; in
{ fetchgit ? pkgs.fetchgit
, callCabal2nix ? pkgs.haskellPackages.callCabal2nix
}:

let
  qbar-repo-def = with builtins; fromJSON (readFile ./repo.json);
  qbar-repo = fetchgit {
    inherit (qbar-repo-def) url rev sha256 ;
  };
in
callCabal2nix "qbar" qbar-repo {}
