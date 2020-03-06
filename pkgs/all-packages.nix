{ lib, config, ... }: pkgs:

with pkgs;

# Lists the packages as attribute sets as if you were in
# `<nixpkgs/pkgs/top-level/all-packages.nix>`.
# They will be added to `pkgs` or override the existing ones.
# Of course, packages can depend on each other, as long as there is no cycle.
let

  unstable = import config.lib.channels."nixos-unstable" {};

  all-hies = import config.lib.channels."all-hies" {};

  yanerpkgs = rec {

    haskell = pkgs.haskell // {
      packageOverrides = self: super: {
        qbar = self.callPackage ./qbar {};
      };
    };

    # redshift-wlr = unstable.redshift-wlr;

    all-hies-latest = all-hies.latest;

  };

in yanerpkgs
