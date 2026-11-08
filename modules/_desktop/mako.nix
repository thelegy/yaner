{ lib, ... }:
with lib;

{
  xdg.configFile."mako/config".text = ''
    max-history=10000

    [mode=dnd]
    invisible=1
  '';
}
