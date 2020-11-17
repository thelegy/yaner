lib:
{ path, name?null }:

with builtins;

let
  generatedName = replaceStrings [".nix"] [""] (baseNameOf path);
in {
  name = if isNull name then generatedName else name;
  value = import path;
}
