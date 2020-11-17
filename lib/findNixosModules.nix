lib:
path:

with builtins;
with lib;

let

  modulePaths = map (module: path + "/${module}") (readFilterDir (not filterDirHidden) path);

in listToAttrs (map (mpath: mkNixosModule {path=mpath;}) modulePaths) 
