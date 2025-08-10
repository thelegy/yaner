{ lib, pkgs }:
{
  pkg,
  name ? null,
  entrypoints ? null,
}:
let
  wrapperName = if name == null || name == "" then pkg.name else name;
  wrapperEntrypoints =
    if entrypoints == null || entrypoints == [ ] then [ "bin/${pkg.pname}" ] else entrypoints;
  mkScript =
    e: output:
    pkgs.writeShellScriptBin wrapperName ''
      set -euo pipefail

      drv=${lib.escapeShellArg (builtins.unsafeDiscardOutputDependency pkg.drvPath)}
      prog=${lib.escapeShellArg e}
      output=${lib.escapeShellArg output}

      # Where the GC-root out-link lives (user-writable by default)
      out_link="''${XDG_CACHE_HOME:-$HOME/.cache}/on-demand-wrappers/${wrapperName}-$output"
      mkdir -p "$(dirname "$out_link")"

      # Realize (or no-op if already realized) and keep GC root updated.
      # Execute via the out-link; no need to capture stdout.
      /run/current-system/sw/bin/nix build \
        --out-link "$out_link" \
        "$drv^$output"

      # Exec via the out-link; multi-output handling is left to the caller
      # (prefix the output in `program`, e.g. "dev/bin/clangd").
      exec "$out_link/$prog" "$@"
    '';
  # Normalize entrypoints → list of { name, path, output }
  normalize =
    ep:
    if builtins.isString ep then
      {
        name = lib.last (lib.splitString "/" ep);
        path = ep;
        output = "out";
      }
    else if builtins.isAttrs ep then
      rec {
        name = (ep.name or (if ep ? path then lib.last (lib.splitString "/" ep.path) else pkg.pname));
        path = (ep.path or "bin/${name}");
        output = (ep.output or "out");
      }
    else
      throw "mkOnDemand: each entrypoint must be a string or an attrset";

  eps = map normalize wrapperEntrypoints;

  # Build scripts and index by their installed name
  scripts = lib.listToAttrs (
    map (ep: {
      name = ep.name;
      value = mkScript ep.path ep.output;
    }) eps
  );
in
pkgs.runCommand "ondemand-${wrapperName}" { } ''
  set -euo pipefail
  mkdir -p "$out/bin"
  ${lib.concatStrings (
    map (n: ''
      cp -f ${builtins.getAttr n scripts}/bin/${wrapperName} "$out/bin/${n}"
      chmod +x "$out/bin/${n}"
    '') (builtins.attrNames scripts)
  )}
''
