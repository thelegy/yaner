name :

with builtins;

let

  channelDef = fromJSON ( readFile ./channel.json );

in fetchGit {
  inherit (channelDef) url rev ref;
}
