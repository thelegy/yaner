{ lib, pkgs, ... }: let

  statusCommand = ''
    ${pkgs.qbar}/bin/qbar server swaybar \
    date \
    battery \
    cpu \
    disk '"/ /tmp"' \
    networkmanager
  '';

  wallpaper = "${pkgs.sway-unwrapped.src}/assets/Sway_Wallpaper_Blue_2048x1536.png";

  screenshotTool = pkgs.writeScript "screenshotTool" ''
    #!${pkgs.zsh}/bin/zsh
    PATH=${pkgs.grim}/bin:${pkgs.slurp}/bin:${pkgs.wl-clipboard}/bin:${pkgs.coreutils}/bin
    slurp -do | grim -g - -t png - | tee "''${XDG_RUNTIME_DIR:-/tmp}/screenshot.png" | wl-copy --type image/png --foreground
  '';
  sensibleCommand = ./sensible-command;
  exitTool = ./exit-tool;

  modeExit = "Press Del to exit sway.";
  modeSystem = "System (l) lock, (e) logout, (s) suspend, (h) hibernate, (r) reboot, (Shift+s) shutdown";

  mod = "Mod4";

  menuCmd = "${pkgs.fuzzel}/bin/fuzzel --dpi-aware no --terminal kitty --border-radius 0 --background 111111e6 --text-color ccccccff --match-color dd5001ff --selection-color 000000e6 --vertical-pad 20 --font 'monospace:size=12' --width 100 --lines 25";

  bar = {
    position = "top";
    fonts.names = [ "monospace" ];
    fonts.size = 7.0;
    statusCommand = statusCommand;
    trayOutput = "*";
    extraConfig = ''
      status_padding 0
      colors {
        focused_background #202020bb
      }
    '';
    # using the colors module is not possible yet, b/c the focusedBackground is missing
    colors = {
      background = "#20202088";
      # this is not implemented yet
      #focusedBackground = "#202020bb";
      statusline = "#eeeeee";
      inactiveWorkspace = {
        border = "#333333cc";
        background = "#202020cc";
        text = "#eeeeee";
      };
    };
  };

in {

  home.packages = [
    pkgs.swaylock
  ];

  wayland.windowManager.sway = {
    enable = true;

    extraConfig = ''
      include local

      titlebar_padding 3 1

      for_window [app_id="^chrome-.*"] shortcuts_inhibitor disable

      bindsym --locked XF86AudioRaiseVolume exec ${pkgs.pamixer}/bin/pamixer --gamma 3 --increase 1 --unmute
      bindsym --locked XF86AudioLowerVolume exec ${pkgs.pamixer}/bin/pamixer --gamma 3 --decrease 1 --unmute

      bindsym --locked Shift+XF86AudioRaiseVolume exec ${pkgs.media_volume} 0.05
      bindsym --locked Shift+XF86AudioLowerVolume exec ${pkgs.media_volume} -0.05

      bindsym --locked XF86AudioPlay exec ${pkgs.playerctl}/bin/playerctl --ignore-player=chromium play-pause
      bindsym --locked XF86AudioStop exec ${pkgs.playerctl}/bin/playerctl --ignore-player=chromium stop
      bindsym --locked XF86AudioPrev exec ${pkgs.playerctl}/bin/playerctl --ignore-player=chromium previous
      bindsym --locked XF86AudioNext exec ${pkgs.playerctl}/bin/playerctl --ignore-player=chromium next

      exec ${pkgs.gammastep}/bin/gammastep -t 5700:3400 -g 1 -l 52:9
      exec ${pkgs.mako}/bin/mako
    '';

    config = {
      modifier = mod;
      terminal = "${sensibleCommand} kitty urxvt";
      input = {
        "type:keyboard" = {
          xkb_layout = "de";
          xkb_variant = "nodeadkeys";
          xkb_numlock = "enable";
          xkb_options = "caps:escape";
        };
        "type:touchpad" = {
          tap = "enabled";
          natural_scroll = "enabled";
        };
      };
      output = {
        "eDP-1" = {
          res = "1920x1080";
          pos = "0,0";
        };
        "*".bg = "${wallpaper} fill";
      };
      bars = [bar];
      menu = menuCmd;
      colors.unfocused = {
        border = "#333333";
        background = "#202020dd";
        text = "#888888";
        indicator = "#292d2e";
        childBorder = "#202020";
      };
      window = {
        border = 0;
        titlebar = true;
        # the value is not implemented yet
        #hideEdgeBorders = "smart_no_gaps";
      };
      gaps = {
        smartBorders = "no_gaps";
        inner = 5;
        outer = -5;
      };
      modes = lib.mkOptionDefault {
        "${modeExit}" = {
          "Delete" = "exit, mode default";

          "Return" = "mode default";
          "Escape" = "mode default";
        };
        "${modeSystem}" = {
          "l" = "exec ${exitTool} lock, mode default";
          "e" = "exec ${exitTool} logout, mode default";
          "s" = "exec ${exitTool} suspend, mode default";
          "h" = "exec ${exitTool} hibernate, mode default";
          "r" = "exec ${exitTool} reboot, mode default";
          "Shift+s" = "exec ${exitTool} shutdown, mode default";

          "Return" = "mode default";
          "Escape" = "mode default";
        };
      };
      keybindings = lib.mkOptionDefault {
        "${mod}+0" = "workspace number 10";
        "${mod}+Shift+0" = "move container to workspace number 10";

        "${mod}+Shift+Return" = "exec ${sensibleCommand} alacritty urxvt";

        "${mod}+Shift+Alt+h" = "move workspace to output left";
        "${mod}+Shift+Alt+j" = "move workspace to output down";
        "${mod}+Shift+Alt+k" = "move workspace to output up";
        "${mod}+Shift+Alt+l" = "move workspace to output right";

        "${mod}+Print" = "exec ${exitTool} lock";
        "${mod}+Shift+Print" = "mode \"${modeSystem}\"";

        "${mod}+Insert" = "exec ${screenshotTool}";

        "${mod}+Shift+e" = "mode \"${modeExit}\"";
      };
    };
  };

}
