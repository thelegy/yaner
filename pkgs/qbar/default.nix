pkgs: self: super: attrs:

let
  qbar-repo-def = with builtins; fromJSON (readFile ./repo.json);
  qbar-repo = pkgs.fetchgit {
    inherit (qbar-repo-def) url rev sha256 ;
  };
in {
  qbar = pkgs.haskell.lib.generateOptparseApplicativeCompletion "qbar" (
    self.callCabal2nix "qbar" qbar-repo attrs
  );
}
