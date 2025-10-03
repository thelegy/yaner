flakes:
{
  lib,
  pkgs,
  ...
}:
{

  imports = [
    flakes.dankMaterialShell.homeModules.dankMaterialShell.default
  ];

  programs.dankMaterialShell.enable = true;

  home.packages = [
    pkgs.xwayland-satellite
  ];
}
