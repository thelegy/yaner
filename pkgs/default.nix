flakes: final: prev:
with final; {
  atopile = python-atopile.pkgs.atopile;

  bs-oneclick = callPackage ./bs-oneclick.nix {};

  cs-firewall-bouncer = callPackage ./cs-firewall-bouncer.nix {};

  formats =
    prev.formats
    // {
      yaml = {}: {
        type = (prev.formats.yaml {}).type;
        generate = name: value:
          final.callPackage ({
            runCommand,
            yq-go,
          }:
            runCommand name {
              nativeBuildInputs = [yq-go];
              value = builtins.toJSON value;
              passAsFile = ["value"];
            } ''
              yq --prettyPrint --no-colors "$valuePath" > $out
            '') {};
      };
    };

  grafana-agent =
    if lib.versionOlder prev.grafana-agent.version "0.36.0"
    then flakes.nixpkgs.legacyPackages.${system}.grafana-agent
    else prev.grafana-agent;

  inxi-full = inxi.override {withRecommends = true;};

  itd = callPackage ./itd.nix {};

  klipper = flakes.nixpkgs-stable.legacyPackages.${final.system}.klipper;

  launch-cadquery = let
    cq-flake = final.fetchFromGitHub {
      owner = "thelegy";
      repo = "cq-flake";
      rev = "9738110d48c2e38f4d03d12839684b06abf34244";
      hash = "sha256-Yq+H4cikZb58JzZP7CPJH/ean78pGMWJDuGLZgI06Eo=";
    };
  in
    on-demand-shell {
      name = "cadquery";
      installable = "path://${cq-flake}";
    };

  lego =
    if lib.versionOlder prev.lego.version "4.9.1"
    then flakes.nixpkgs.legacyPackages.${system}.lego
    else prev.lego;

  media_volume = callPackage ./media_volume.nix {};

  mpv_autospeed = ./mpv_autospeed.lua;

  neovim-thelegy = flakes.qed.packages.${system}.qed;

  nixGL = final.nixgl.nixGLCommon final.nixgl.nixGLIntel;

  on-demand-shell = {
    name,
    scriptName ? "launch-${name}",
    installable ? null,
    args ? "",
  }:
    writeShellScriptBin scriptName ''
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

  preprocess-cancellation = python3Packages.preprocess-cancellation.overrideAttrs (orig: {
    postPatch = ''
      ${orig.postPatch}
      sed -i 's/\[tool.poetry.scripts\]/[project.scripts]/' -i pyproject.toml
      sed -i 's/\[tool.poetry\]/[project]/' -i pyproject.toml
      sed -i 's/license *=.*//' -i pyproject.toml
      sed -i 's/authors *=.*//' -i pyproject.toml
      sed -i 's/repository *=.*//' -i pyproject.toml
      cat pyproject.toml
    '';
  });

  python-atopile = python311.override {
    self = __splicedPackages.python-atopile;
    packageOverrides = pfinal: pprev: {
      atopile = pfinal.callPackage ./atopile/atopile.nix {};
      case-converter = pfinal.callPackage ./atopile/case-converter.nix {};
      docopt_subcommands = pfinal.callPackage ./atopile/docopt-subcommands.nix {};
      easyeda2ato = pfinal.callPackage ./atopile/easyeda2ato.nix {};
      eseries = pfinal.callPackage ./atopile/eseries.nix {};
    };
  };

  qbar = flakes.qbar.packages.${system}.qbar;

  typst-languagetool = callPackage ./typst-languagetool.nix {};
  typst-languagetool-lsp = callPackage ./typst-languagetool.nix {lsp = true;};
}
