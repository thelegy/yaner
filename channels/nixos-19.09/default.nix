name :

with builtins;

let

  channelDef = fromJSON ( readFile ./channel.json );

in fetchGit {
  inherit name;
  inherit (channelDef) url rev ref;
}
