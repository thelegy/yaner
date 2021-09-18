{ config, options, pkgs, ... }:

{

  imports = [
    ./pulseaudio.nix
  ];
  wat.thelegy.base.enable = true;


  hardware.opengl.enable = true;

  programs = {
    chromium = {
      enable = true;
      extensions = [
        "cjpalhdlnbpafiamejdnhcphjbkeiagm" # ublock origin
      ];
    };

    # Enable sway to ensure pam is configured properly for swaylock
    sway.enable = true;
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
      mpv
      python3
      qbar
      redshift-wlr
      slurp
      spotify
      translate-shell
      wl-clipboard
      youtube-dl
    ];
  };

  home-manager.users.beinke = { ... }: {
    imports = [
      ./kitty.nix
      ./mako.nix
      ./sway
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
