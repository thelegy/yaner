{ ... }: {

  programs.kitty = {
    enable = true;
    settings = {
      box_drawing_scale = ".001, .25, 1, 2";

      font_size = 9;

      term = "xterm-kitty";

      foreground = "#d0d0d0";
      background = "#202020";
      background_opacity = ".95";

      scrollback_lines = 10000;

      visual_bell_duration = ".01";
      window_alert_on_bell = true;
    };
    keybindings = {
      "kitty_mod+plus" = "change_font_size all +1.0";
      "kitty_mod+minus" = "change_font_size all -1.0";
      "kitty_mod+backspace" = "change_font_size all 0";
    };
  };

}
