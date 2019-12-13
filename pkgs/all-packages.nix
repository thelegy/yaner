{ lib, config, ... }: pkgs:

with pkgs;

# Lists the packages as attribute sets as if you were in
# `<nixpkgs/pkgs/top-level/all-packages.nix>`.
# They will be added to `pkgs` or override the existing ones.
# Of course, packages can depend on each other, as long as there is no cycle.
let

  unstable = import <nixos-unstable> {};

  all-hies-repo = fetchFromGitHub {
    owner = "infinisil";
    repo = "all-hies";
    rev = "c4fad117eb79305f5b8bc77a6a28562a5f8d2ca3";
    sha256 = "19spg5xnb1gdnxal4vp402dknfhbva5jj5yq34qyzvksyn16c3dp";
  };
  all-hies = import all-hies-repo {};

  yanerpkgs = rec {

    redshift-wlr = unstable.redshift-wlr;

    all-hies-latest = all-hies.latest;

  };

in yanerpkgs
