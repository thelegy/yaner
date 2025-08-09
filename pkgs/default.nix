flakes: final: prev:
with final; {
  atopile = python-atopile.pkgs.atopile;

  bs-oneclick = callPackage ./bs-oneclick.nix {};

  crowdsec =
    (
      if lib.versionOlder prev.crowdsec.version "1.6.0"
      then flakes.nixpkgs.legacyPackages.${system}.crowdsec
      else prev.crowdsec
    )
    .overrideAttrs (orig: {ldflags = builtins.map (lib.replaceStrings ["refs/tags/"] [""]) orig.ldflags;});

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

  kicad-small = prev.kicad-small.override { python3 = python311; };

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
    if lib.versionOlder prev.lego.version "4.13.2"
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

  opensshWithKerberos =
    if lib.hasAttr "opensshWithKerberos" prev
    then prev.opensshWithKerberos
    else prev.openssh;

  pkgs-unstable = flakes.nixpkgs.legacyPackages.${system};

  preprocess-cancellation = python3Packages.preprocess-cancellation;

  probe-rs-udev =
    runCommand "probe-rs-udev" {
      src = fetchFromGitHub {
        owner = "probe-rs";
        repo = "webpage";
        rev = "c8dbcf0";
        hash = "sha256-hZv+rZ+aY4sxfBgS2xxdLnfNQh9W1SvYGIBjGUIcPbg=";
      };
    } ''
      mkdir -p "$out/etc/udev/rules.d"
      cp "$src/src/static/files/69-probe-rs.rules" "$out/etc/udev/rules.d/"
    '';

  python-atopile = python311.override {
    self = __splicedPackages.python-atopile;
    packageOverrides = pfinal: pprev: {
      atopile = pfinal.callPackage ./atopile/atopile.nix {};
      case-converter = pfinal.callPackage ./atopile/case-converter.nix {};
      docopt_subcommands = pfinal.callPackage ./atopile/docopt-subcommands.nix {};
      easyeda2ato = pfinal.callPackage ./atopile/easyeda2ato.nix {};
      eseries = pfinal.callPackage ./atopile/eseries.nix {};
      quart-schema = pfinal.callPackage ./atopile/quart-schema.nix {};
    };
  };

  qbar = flakes.qbar.packages.${system}.qbar;

  typst-languagetool = callPackage ./typst-languagetool.nix {};
  typst-languagetool-lsp = callPackage ./typst-languagetool.nix {lsp = true;};

  with-scope = callPackage ./with-scope.nix {};
}
