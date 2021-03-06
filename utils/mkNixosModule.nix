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

    mkModule = { options?{}, config }: let
      moduleConfig = config;
      mkModule_ = { config, lib, ... }: let
        cfg = extractFromNamespace config;
        baseOptions = liftToNamespace {enable = lib.mkEnableOption "Enable the ${moduleName} config layer";};
      in {
        options = baseOptions // options;
        config = lib.mkIf cfg.enable (moduleConfig cfg);
      };
    in { imports = [ mkModule_ ]; };

    mkTrivialModule = module: mkModule { config = _: module; };

  };

  filterFunctionArgs = attrs: removeAttrs attrs (attrNames additionalModuleArgs);

  wrapModule = module:
    if lib.isFunction module then
    lib.setFunctionArgs (moduleArgs: (module (additionalModuleArgs // moduleArgs)))
      (filterFunctionArgs (lib.functionArgs module))
    else module;

in {
  name = moduleName;
  value = wrapModule (import path);
}
