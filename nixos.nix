# Returns a NixOS system configuration for $hostname
{ hostname }:

let

  plumbing = (import ./default.nix);

  # channel :: path
  channel = plumbing.channels.${hostname};

  # configuration :: system_configuration
  configuration = plumbing.configurations.${hostname};

  nixos = import "${channel}/nixos" {
    system = "x86_64-linux";
    configuration = configuration;
  };

in
nixos.system
