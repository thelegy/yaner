flakes: final: prev:

with final;

{

  inxi-full = inxi.override { withRecommends = true; };

  media_volume = callPackage ./media_volume.nix {};

  mpv_autospeed = ./mpv_autospeed.lua;

  kicad = flakes.nixpkgs-staging-next.legacyPackages.${system}.kicad;

}
