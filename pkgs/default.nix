flakes: final: prev:

with final;

{

  fuzzel = flakes.nixpkgs-staging-next.legacyPackages.${system}.fuzzel;

  inxi-full = inxi.override { withRecommends = true; };

  media_volume = callPackage ./media_volume.nix {};

  mpv_autospeed = ./mpv_autospeed.lua;

}
