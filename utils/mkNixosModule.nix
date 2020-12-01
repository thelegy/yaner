{ lib, utils, ... }:
{ path, name?null, namespace?[] }:

with builtins;

let

  generatedName = replaceStrings [".nix"] [""] (baseNameOf path);

  moduleName = if isNull name then generatedName else name;

  moduleNamespace = namespace ++ [moduleName];

  additionalModuleArgs = rec {

    inherit moduleName;

    liftToNamespace = contents: lib.foldr (a: b: {"${a}" = b;}) contents moduleNamespace;

    extractFromNamespace = o: lib.foldl (a: b: a."${b}") o moduleNamespace;

    mkToggleableModule = module: let
      mkToggleableModule_ = moduleArgs@{ config, lib, ... }: let
        cfg = extractFromNamespace config;
        moduleEffect = if isFunction module then module moduleArgs else module;
      in {
        options = liftToNamespace {enable = lib.mkEnableOption "Enable the ${moduleName} config layer";};
        config = lib.mkIf cfg.enable moduleEffect;
      };
    in { imports = [mkToggleableModule_]; };

  };

  wrapModule = module:
    if isFunction module then
      moduleArgs@{pkgs, ...}:
      module (additionalModuleArgs // moduleArgs)
    else module;

in {
  name = moduleName;
  value = wrapModule (import path);
}
