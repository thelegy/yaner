flakes: final: prev:

with final;

{

  qbar = flakes.qbar.packages.${system}.qbar;

  inxi-full = inxi.override { withRecommends = true; };

  media_volume = callPackage ./media_volume.nix {};

  mpv_autospeed = ./mpv_autospeed.lua;

  neovim-thelegy = flakes.qed.packages.${final.system}.qed;

  bs-oneclick = callPackage ./bs-oneclick.nix {};

  itd = callPackage ./itd.nix {};

  lego =
    if lib.versionOlder prev.lego.version "4.9.1"
    then flakes.nixpkgs.legacyPackages.${system}.lego
    else prev.lego;

}
