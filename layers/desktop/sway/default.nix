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

  sensibleCommand = ./sensible-command;
  exitTool = ./exit-tool;

  modeExit = "Press Del to exit sway.";
  modeSystem = "System (l) lock, (e) logout, (s) suspend, (h) hibernate, (r) reboot, (Shift+s) shutdown";

  mod = "Mod4";

  bar = {
    position = "top";
    fonts = ["monospace 7"];
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
      titlebar_padding 3 1
    '';

    config = {
      modifier = mod;
      terminal = "${sensibleCommand} kitty urxvt";
      input = {
        "type:keyboard" = {
          xkb_layout = "de";
          xkb_variant = "nodeadkeys";
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
          "l" = "exec --no-startup-id ${exitTool} lock, mode default";
          "e" = "exec --no-startup-id ${exitTool} logout, mode default";
          "s" = "exec --no-startup-id ${exitTool} suspend, mode default";
          "h" = "exec --no-startup-id ${exitTool} hibernate, mode default";
          "r" = "exec --no-startup-id ${exitTool} reboot, mode default";
          "Shift+s" = "exec --no-startup-id ${exitTool} shutdown, mode default";

          "Return" = "mode default";
          "Escape" = "mode default";
        };
      };
      keybindings = lib.mkOptionDefault {
        "${mod}+0" = "workspace number 10";
        "${mod}+Shift+0" = "move container to workspace number 10";
        "${mod}+Shift+Return" = "exec ${sensibleCommand} alacritty urxvt";
        "${mod}+Print" = "exec --no-startup-id ${exitTool} lock";
        "${mod}+Shift+Print" = "mode \"${modeSystem}\"";
        "${mod}+Shift+e" = "mode \"${modeExit}\"";
      };
    };
  };

}
