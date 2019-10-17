
let

  # readFilterDir :: ({name:string, path:path, type:string, ...} -> bool) -> path -> [string]
  readFilterDir = with builtins; lambda: path: let
    dirContents = readDir path;
    filterFunc = name: lambda rec {
      inherit name;
      path = path + "/${name}";
      type = dirContents.${name};
    };
  in filter filterFunc (attrNames dirContents);

  # readVisibleDir :: path -> [ string ]
  readVisibleDir = readFilterDir ({ name, ... }:
    (builtins.substring 0 1 name) != ".");

  # extraModuleList :: [ path ]
  extraModuleList = with builtins; map (module: ./modules + "/${module}") (readVisibleDir ./modules);

  # makeHost :: { hostName:string, hostPath:path } -> system_config
  makeHost = 
    { hostName, hostPath }:
    { config, pkgs, lib, ... }: {
      imports = [ hostPath ] ++ extraModuleList;
      nixpkgs.config = {
        packageOverrides = (import ./pkgs/all-packages.nix) lib;
      };
      networking.hostName = lib.mkDefault hostName;
      system.stateVersion = lib.mkDefault "19.09";
    };

  # hostModules :: { *:system_config }
  hostModules =
    builtins.listToAttrs (map (hostName: {
      name = hostName;
      value = makeHost {
        inherit hostName;
        hostPath = (./hosts + "/${hostName}");
      };
    }) (readVisibleDir ./hosts));
in

hostModules
