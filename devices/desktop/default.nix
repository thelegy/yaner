{ config, options, pkgs, ... }:

{

  imports = [
    ../box
    ./pulseaudio.nix
  ];


  hardware.opengl.enable = true;
  
  hardware.u2f.enable = true;

  programs = {
    chromium.enable = true;
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
    extraGroups = [ "networkmanager" "video" "audio" ];
    packages = with pkgs; [
      chromium
      python3
      kitty
      alacritty
      mpv
      youtube-dl
    ];
  };

  fonts.fonts = with pkgs; [
    fira-code
    font-awesome-ttf
  ];

  environment.systemPackages = with pkgs; [
    pinentry
    glxinfo
  ];

}
