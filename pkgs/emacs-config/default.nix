{ lib
, trivialBuild
, helm
}:

trivialBuild rec {

  pname = "emacs-config";

  src = ./.;

  packageRequires = [ helm ];

  meta.maintainers = with lib.maintainers; [ thelegy ];

}
