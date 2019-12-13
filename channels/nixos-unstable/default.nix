with builtins;

let

  channelDef = fromJSON ( readFile ./channel.json );

in fetchGit {
  name = "nixpkgs-unstable";
  ref = "nixos-unstable";
  inherit (channelDef) url rev;
}
