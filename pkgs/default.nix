flakes: final: prev:

with final;

{

  bs-oneclick = callPackage ./bs-oneclick.nix {};

  inxi-full = inxi.override { withRecommends = true; };

  itd = callPackage ./itd.nix {};

  lego =
    if lib.versionOlder prev.lego.version "4.9.1"
    then flakes.nixpkgs.legacyPackages.${system}.lego
    else prev.lego;

  media_volume = callPackage ./media_volume.nix {};

  mpv_autospeed = ./mpv_autospeed.lua;

  neovim-thelegy = flakes.qed.packages.${final.system}.qed;

  preprocess-cancellation =
    final.python3Packages.preprocess-cancellation.overrideAttrs (orig:{
      postPatch = ''
      ${orig.postPatch}
      sed -i 's/\[tool.poetry.scripts\]/[project.scripts]/' -i pyproject.toml
      '';
    });

  qbar = flakes.qbar.packages.${system}.qbar;

}
