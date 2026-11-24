flakes: final: prev:
let
  system = final.stdenv.hostPlatform.system;
in
{
  appimage-run = prev.appimage-run.override {
    buildFHSEnv =
      args:
      final.buildFHSEnv (
        args
        // {
          # Share host trust without loading SSH config whose root-owned
          # Includes fail ownership checks in bubblewrap's user namespace.
          extraBwrapArgs = (args.extraBwrapArgs or [ ]) ++ [
            "--dir /etc/ssh"
            "--symlink /.host-etc/ssh/ssh_known_hosts /etc/ssh/ssh_known_hosts"
          ];
        }
      );
  };

  atopile = final.python-atopile.pkgs.atopile;

  bs-oneclick = final.callPackage ./bs-oneclick.nix { };

  crowdsec =
    (
      if final.lib.versionOlder prev.crowdsec.version "1.6.0" then
        flakes.nixpkgs.legacyPackages.${system}.crowdsec
      else
        prev.crowdsec
    ).overrideAttrs
      (orig: {
        ldflags = builtins.map (final.lib.replaceStrings [ "refs/tags/" ] [ "" ]) orig.ldflags;
      });

  cs-firewall-bouncer = final.callPackage ./cs-firewall-bouncer.nix { };

  formats = prev.formats // {
    yaml =
      { }:
      {
        type = (prev.formats.yaml { }).type;
        generate =
          name: value:
          final.callPackage (
            {
              runCommand,
              yq-go,
            }:
            runCommand name
              {
                nativeBuildInputs = [ yq-go ];
                value = builtins.toJSON value;
                passAsFile = [ "value" ];
              }
              ''
                yq --prettyPrint --no-colors "$valuePath" > $out
              ''
          ) { };
      };
  };

  inxi-full = final.inxi.override { withRecommends = true; };

  kicad-small = prev.kicad-small.override { python3 = final.python311; };

  launch-cadquery =
    let
      cq-flake = final.fetchFromGitHub {
        owner = "thelegy";
        repo = "cq-flake";
        rev = "9738110d48c2e38f4d03d12839684b06abf34244";
        hash = "sha256-Yq+H4cikZb58JzZP7CPJH/ean78pGMWJDuGLZgI06Eo=";
      };
    in
    final.on-demand-shell {
      name = "cadquery";
      installable = "path://${cq-flake}";
    };

  media_volume = final.callPackage ./media_volume.nix { };

  mkOnDemand = final.callPackage ./mkOnDemand.nix { };

  mpv_autospeed = ./mpv_autospeed.lua;

  neovim-thelegy = flakes.qed.packages.${system}.default;

  on-demand-shell =
    {
      name,
      scriptName ? "launch-${name}",
      installable ? null,
      args ? "",
    }:
    final.writeShellScriptBin scriptName ''
      set -euo pipefail
      readonly gc_root_dir="''${XDG_DATA_HOME:-$HOME/.local/share}/nix-on-demand"
      mkdir -p "$gc_root_dir"
      ${final.lib.optionalString (
        !isNull installable
      ) ''nix build --out-link "$gc_root_dir/${name}" '${installable}' ''}
      exec nix shell "$gc_root_dir/${name}" ${args} "$@"
    '';

  opensshWithKerberos =
    if final.lib.hasAttr "opensshWithKerberos" prev then prev.opensshWithKerberos else prev.openssh;

  pkgs-unstable = flakes.nixpkgs.legacyPackages.${system};

  preprocess-cancellation = final.python3Packages.preprocess-cancellation;

  probe-rs-udev =
    final.runCommand "probe-rs-udev"
      {
        src = final.fetchFromGitHub {
          owner = "probe-rs";
          repo = "webpage";
          rev = "c8dbcf0";
          hash = "sha256-hZv+rZ+aY4sxfBgS2xxdLnfNQh9W1SvYGIBjGUIcPbg=";
        };
      }
      ''
        mkdir -p "$out/etc/udev/rules.d"
        cp "$src/src/static/files/69-probe-rs.rules" "$out/etc/udev/rules.d/"
      '';

  python-atopile = final.python311.override {
    self = final.__splicedPackages.python-atopile;
    packageOverrides = pfinal: pprev: {
      atopile = pfinal.callPackage ./atopile/atopile.nix { };
      case-converter = pfinal.callPackage ./atopile/case-converter.nix { };
      docopt_subcommands = pfinal.callPackage ./atopile/docopt-subcommands.nix { };
      easyeda2ato = pfinal.callPackage ./atopile/easyeda2ato.nix { };
      eseries = pfinal.callPackage ./atopile/eseries.nix { };
      quart-schema = pfinal.callPackage ./atopile/quart-schema.nix { };
    };
  };

  roc-toolkit-sox = final.roc-toolkit.overrideAttrs (orig: {
    sconsFlags = final.lib.filter (x: x != "--disable-sox") orig.sconsFlags;
    buildInputs = (orig.buildInputs or [ ]) ++ [ final.sox ];
  });

  typst-languagetool = final.callPackage ./typst-languagetool.nix { };
  typst-languagetool-lsp = final.callPackage ./typst-languagetool.nix { lsp = true; };

  with-scope = final.callPackage ./with-scope.nix { };
}
