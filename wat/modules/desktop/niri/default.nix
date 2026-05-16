flakes:
{
  lib,
  pkgs,
  ...
}:
let
  qt = pkgs.qt6;
in
{

  imports = [
    flakes.dankMaterialShell.homeModules.dank-material-shell
  ];

  programs.dankMaterialShell = {
    enable = true;
    systemd.enable = true;
  };

  systemd.user.services.dms = {
    Service.Environment = [
      "NIXPKGS_QT6_QML_IMPORT_PATH=\"${qt.qtwebsockets}/${qt.qtbase.qtQmlPrefix}\""
    ];
  };

  home.packages = [
    pkgs.libqalculate
    pkgs.xwayland-satellite
  ];
}
