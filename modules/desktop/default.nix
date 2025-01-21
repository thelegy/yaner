{ mkTrivialModule
, config
, options
, pkgs
, ... }:

mkTrivialModule {

  wat.thelegy.base.enable = true;
  wat.thelegy.audio.enable = true;

  hardware.graphics.enable = true;

  programs = {
    chromium = {
      enable = true;
      extensions = [
        "cjpalhdlnbpafiamejdnhcphjbkeiagm" # ublock origin
      ];
    };

    # Enable sway to ensure pam is configured properly for swaylock
    sway.enable = true;

    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
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
      firefox
      foot
      grim
      mpv
      python3
      qbar
      slurp
      spotify
      translate-shell
      wl-clipboard
      wl-mirror
      yt-dlp
    ];
  };

  boot.binfmt.registrations.appimage = {
    wrapInterpreterInShell = false;
    interpreter = "${pkgs.appimage-run}/bin/appimage-run";
    recognitionType = "magic";
    offset = 0;
    mask = ''\xff\xff\xff\xff\x00\x00\x00\x00\xff\xff\xff'';
    magicOrExtension = ''\x7fELF....AI\x02'';
  };

  home-manager.users.beinke = { ... }: {
    imports = [
      ./foot.nix
      ./kitty.nix
      ./mako.nix
      ./sway
    ];
  };

  fonts = {
    packages = with pkgs; [
      nerd-fonts.fira-code
    ];
    fontconfig.defaultFonts.monospace = [ "FiraCode Nerd Font" ];
  };

  environment.systemPackages = with pkgs; [
    pinentry
    pinentry-gtk2
    glxinfo
  ];

}
