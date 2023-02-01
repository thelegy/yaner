flakes: final: prev:

with final;

{

  bs-oneclick = callPackage ./bs-oneclick.nix {};

  cadquery-env = let
    cadquery-python = flakes.cadquery.packages.${system}.python;
    cq-kit = lib.head (lib.filter (p: p.pname == "cq-kit") cq-editor.propagatedBuildInputs);
    pythonBundle = cadquery-python.withPackages (p: with p; [
      cadquery
      cq-kit
      #ocp-stubs
      #pybind11-stubgen
    ]);
  in buildEnv {
    name = "cadquery-env";
    paths = [ cq-editor pythonBundle ];
  };

  cq-editor = flakes.cadquery.packages.${system}.cq-editor;

  inxi-full = inxi.override { withRecommends = true; };

  itd = callPackage ./itd.nix {};

  lego =
    if lib.versionOlder prev.lego.version "4.9.1"
    then flakes.nixpkgs.legacyPackages.${system}.lego
    else prev.lego;

  media_volume = callPackage ./media_volume.nix {};

  mpv_autospeed = ./mpv_autospeed.lua;

  neovim-thelegy = flakes.qed.packages.${system}.qed;

  preprocess-cancellation =
    python3Packages.preprocess-cancellation.overrideAttrs (orig:{
      postPatch = ''
      ${orig.postPatch}
      sed -i 's/\[tool.poetry.scripts\]/[project.scripts]/' -i pyproject.toml
      '';
    });

  qbar = flakes.qbar.packages.${system}.qbar;

}
