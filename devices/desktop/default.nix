{ config, options, pkgs, ... }:

{

  imports = [
    ../box
  ];


  hardware.opengl.enable = true;

  programs = {
    chromium.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    sway = {
      enable = true;
      extraSessionCommands = ''
        export XKB_DEFAULT_LAYOUT=de
        export XKB_DEFAULT_VARIANT=nodeadkeys
      '';
    };
  };

  networking.networkmanager = {
    enable = true;
  };

  users.users.beinke = {
    extraGroups = [ "networkmanager" ];
    packages = with pkgs; [
      chromium
      python3
      kitty
      alacritty
    ];
  };

  fonts.fonts = with pkgs; [
    fira-code
    font-awesome-ttf
  ];

}
