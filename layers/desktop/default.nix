{ config, options, pkgs, ... }:

{

  imports = [
    ../box
    ./pulseaudio.nix
    ./sway
  ];


  hardware.opengl.enable = true;

  hardware.u2f.enable = true;

  programs = {
    chromium.enable = true;
  };

  networking.networkmanager = {
    enable = true;
  };

  users.users.beinke = {
    extraGroups = [ "networkmanager" "video" "audio" ];
    packages = with pkgs; [
      redshift-wlr
      chromium
      python3
      kitty
      alacritty
      mpv
      youtube-dl
      qbar
    ];
  };

  fonts.fonts = with pkgs; [
    fira-code
  ];

  environment.systemPackages = with pkgs; [
    pinentry
    glxinfo
  ];

}
