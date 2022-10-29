{ mkTrivialModule
, lib
, pkgs
, ...
}: with lib;

let
  bs-install-dir = "/home/beinke/.local/share/Steam/steamapps/common/Beat Saber";
  bs-oneclick = pkgs.bs-oneclick.override { inherit bs-install-dir; };
in
mkTrivialModule {

  home-manager.users.beinke = { ... }: {

    xdg.desktopEntries."bs-oneclick" = {
      exec = "${bs-oneclick}/bin/bs-oneclick %u";
      name = "Beat Saber OneClick Install";
      type = "Application";
      startupNotify = false;
      mimeType = [
        "x-scheme-handler/beatsaver"
        "x-scheme-handler/modelsaber"
        "x-scheme-handler/bsplaylist"
      ];
      noDisplay = true;
    };

  };

}
