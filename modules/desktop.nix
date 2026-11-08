{ wat, ... }:
{
  flake.nixosModules.desktop = wat.mkModuleWrapped [ "desktop" ] (
    {
      cfg,
      flakes,
      pkgs,
      ...
    }:

    let
      # pinentry-gnome3 uses DBus connection, thus the curses fallback does not happen reliably over SSH
      pinentryPackage = pkgs.pinentry-qt;
    in
    {

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
          inherit pinentryPackage;
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
        extraPortals = [
          pkgs.xdg-desktop-portal-gtk
          pkgs.xdg-desktop-portal-wlr
        ];
      };
      # environment.sessionVariables.GTK_USE_PORTAL = "1";
      environment.sessionVariables.NIXOS_OZONE_WL = "1";

      services.earlyoom.enable = true;

      users.users.beinke = {
        extraGroups = [
          "networkmanager"
          "video"
          "audio"
        ];
        packages = [
          pkgs.alacritty
          pkgs.chromium
          pkgs.firefox
          pkgs.foot
          pkgs.grim
          pkgs.mpv
          pkgs.slurp
          pkgs.spotify
          pkgs.translate-shell
          pkgs.uv
          pkgs.wl-clipboard
          pkgs.wl-mirror
          pkgs.yt-dlp
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
            ./_desktop/foot.nix
            ./_desktop/kitty.nix
            ./_desktop/mako.nix
            ./_desktop/sway
          ];
        };

      fonts = {
        packages = [
          pkgs.nerd-fonts.fira-code
          pkgs.material-symbols
        ];
        fontconfig.defaultFonts.monospace = [ "FiraCode Nerd Font" ];
      };

      environment.systemPackages = [
        pinentryPackage
        pkgs.gearlever
        pkgs.gsettings-desktop-schemas
        pkgs.libqalculate
        pkgs.mesa-demos
        pkgs.phinger-cursors
        pkgs.xwayland-satellite
      ];

      services.xserver.xkb = {
        layout = "de";
        variant = "nodeadkeys";
        options = "caps:escape_shifted_capslock,compose:rctrl";
      };

      programs.dux-shell = {
        enable = true;
        plugins = {
          calculator.enable = true;
          niriDSA.enable = true;
          niriWindows.enable = true;
          quickCapture.enable = true;
        };
      };

      programs.dux-search.enable = true;

      # systemd.user.services.dms = {
      #   Service.Environment = [
      #     "NIXPKGS_QT6_QML_IMPORT_PATH=\"${qt.qtwebsockets}/${qt.qtbase.qtQmlPrefix}\""
      #   ];
      # };

      services.displayManager.dux-greeter = {
        enable = true;
        compositor.name = "niri";
        configHome = "/home/beinke";
      };

    }

  );
}
