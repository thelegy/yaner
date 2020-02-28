{ fetchgit, callCabal2nix, haskell }:

let
  qbar-repo-def = with builtins; fromJSON (readFile ./repo.json);
  qbar-repo = fetchgit {
    inherit (qbar-repo-def) url rev sha256 ;
  };
in haskell.lib.generateOptparseApplicativeCompletion "qbar" (
  callCabal2nix "qbar" qbar-repo {}
)
