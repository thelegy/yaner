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

  launch-cadquery = on-demand-shell {
    name = "cadquery";
    installable = "${flakes.self}#cadquery-env";
  };

  lego =
    if lib.versionOlder prev.lego.version "4.9.1"
    then flakes.nixpkgs.legacyPackages.${system}.lego
    else prev.lego;

  media_volume = callPackage ./media_volume.nix {};

  mpv_autospeed = ./mpv_autospeed.lua;

  neovim-thelegy = flakes.qed.packages.${system}.qed;

  on-demand-shell =
    { name
    , scriptName ? "launch-${name}"
    , installable ? null
    , args ? ""
    }: writeShellScriptBin scriptName ''
      set -euo pipefail
      readonly gc_root_dir="''${XDG_DATA_HOME:-$HOME/.local/share}/nix-on-demand"
      mkdir -p "$gc_root_dir"
      ${
        lib.optionalString
          (!isNull installable)
          ''nix build --out-link "$gc_root_dir/${name}" '${installable}' ''
      }
      exec nix shell "$gc_root_dir/${name}" ${args} "$@"
    '';

  preprocess-cancellation =
    python3Packages.preprocess-cancellation.overrideAttrs (orig:{
      postPatch = ''
      ${orig.postPatch}
      sed -i 's/\[tool.poetry.scripts\]/[project.scripts]/' -i pyproject.toml
      '';
    });

  qbar = flakes.qbar.packages.${system}.qbar;

}
