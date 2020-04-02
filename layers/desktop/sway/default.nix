{ pkgs, ... }:

{
  hardware.opengl.enable = true;

  programs = {
    sway = {
      enable = true;
      extraSessionCommands = ''
        export XKB_DEFAULT_LAYOUT=de
        export XKB_DEFAULT_VARIANT=nodeadkeys
      '';
      extraPackages = with pkgs; [
        swaylock
        swayidle
        xwayland
        xorg.xrdb
        dmenu
      ];
    };
  };
}
