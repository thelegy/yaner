{ ... }:

{
  disabledModules = [ "programs/sway.nix" ];

  imports = [
    ./..
    <nixos-unstable/nixos/modules/programs/sway.nix>
  ];

}