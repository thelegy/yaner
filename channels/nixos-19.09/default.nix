with builtins;

let

  channelDef = fromJSON ( readFile ./channel.json );

in fetchGit {
  name = "nixpkgs-19.09";
  ref = "nixos-19.09";
  inherit (channelDef) url rev;
}
