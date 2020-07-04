# Returns a NixOS system configuration for $hostname
{ hostname }:

let

  plumbing = (import ./default.nix);

in {
  system = plumbing.systems.${hostname};
  iso = plumbing.isos.${hostname};
  sdcard = plumbing.sdcards.${hostname};
  channel = plumbing.channels.${hostname};
}
