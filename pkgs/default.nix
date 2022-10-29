flakes: final: prev:

with final;

{

  qbar = flakes.qbar.packages.${system}.qbar;

  fuzzel = flakes.nixpkgs-staging-next.legacyPackages.${system}.fuzzel;

  inxi-full = inxi.override { withRecommends = true; };

  media_volume = callPackage ./media_volume.nix {};

  mpv_autospeed = ./mpv_autospeed.lua;

  neovim-thelegy = flakes.qed.packages.${final.system}.qed;

  itd = callPackage ./itd.nix {};

}
