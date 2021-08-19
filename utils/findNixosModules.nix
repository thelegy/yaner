{ utils, ... }:
{ path, namespace?[] }:

with builtins;
with utils;

let

  modulePaths = map (module: path + "/${module}") (readFilterDir (not filterDirHidden) path);

in listToAttrs (map (mpath: mkNixosModule {path=mpath; inherit namespace;}) modulePaths)
