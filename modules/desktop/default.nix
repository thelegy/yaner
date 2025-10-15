{
  mkTrivialModule,
  config,
  flakes,
  options,
  pkgs,
  ...
}:

mkTrivialModule {

  wat.thelegy.base.enable = true;
  wat.thelegy.audio.enable = true;

  hardware.graphics.enable = true;

  services.upower = {
    enable = true;
  };

  programs = {
    chromium = {
      enable = true;
      extensions = [
        "cjpalhdlnbpafiamejdnhcphjbkeiagm" # ublock origin
      ];
    };

    # Enable sway to ensure pam is configured properly for swaylock
    sway = {
      enable = true;
      wrapperFeatures.gtk = true;
    };

    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage = pkgs.pinentry-gnome3;
    };

    foot.enable = true;
  };

  networking.networkmanager = {
    enable = true;
  };

  programs.sway.extraSessionCommands = ''
    export GTK_THEME=Blackbird
    export GTK_ICON_THEME=Tango
    export MOZ_ENABLE_WAYLAND=1
    export MOZ_USE_XINPUT2=1
    export XDG_SESSION_TYPE=wayland
    export XDG_CURRENT_DESKTOP=sway
  '';

  programs.niri.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-wlr
    ];
  };
  # environment.sessionVariables.GTK_USE_PORTAL = "1";
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  users.users.beinke = {
    extraGroups = [
      "networkmanager"
      "video"
      "audio"
    ];
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

  home-manager.users.beinke =
    { ... }:
    {
      imports = [
        ./foot.nix
        ./kitty.nix
        ./mako.nix
        (import ./niri flakes)
        ./sway
      ];
    };

  fonts = {
    packages = with pkgs; [
      nerd-fonts.fira-code
      material-symbols
    ];
    fontconfig.defaultFonts.monospace = [ "FiraCode Nerd Font" ];
  };

  environment.systemPackages = with pkgs; [
    glxinfo
    gsettings-desktop-schemas
    phinger-cursors
    pinentry
    pinentry-gtk2
  ];

}
