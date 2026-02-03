flakes:
{
  lib,
  pkgs,
  ...
}:
{

  imports = [
    flakes.dankMaterialShell.homeModules.dank-material-shell
  ];

  programs.dankMaterialShell.enable = true;

  home.packages = [
    pkgs.xwayland-satellite
  ];
}
