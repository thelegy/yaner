{ config, options, pkgs, ... }:

{

  imports = [
    ../box
    ./pulseaudio.nix
    ./sway
  ];


  hardware.opengl.enable = true;

  programs = {
    chromium = {
      enable = true;
      extensions = [
        "cjpalhdlnbpafiamejdnhcphjbkeiagm" # ublock origin
      ];
    };
  };

  networking.networkmanager = {
    enable = true;
  };

  users.users.beinke = {
    extraGroups = [ "networkmanager" "video" "audio" ];
    packages = with pkgs; [
      alacritty
      chromium
      grim
      kitty
      mpv
      python3
      qbar
      redshift-wlr
      slurp
      spotify
      wl-clipboard
      youtube-dl
    ];
  };

  fonts = {
    fonts = with pkgs; [
      (nerdfonts.override {fonts = [ "FiraCode" ];})
    ];
    fontconfig.defaultFonts.monospace = [ "FiraCode Nerd Font" ];
  };

  environment.systemPackages = with pkgs; [
    pinentry
    pinentry-gtk2
    glxinfo
  ];

}
