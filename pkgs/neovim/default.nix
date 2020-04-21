{ neovim, vimPlugins }:

neovim.override {
  configure = {
    customRC = ''
      inoremap fd <Esc>
      vnoremap fd <Esc>

      set shiftwidth=2
      set expandtab
      set shiftround

      set smartindent
      filetype plugin indent on

      set number

      colorscheme gruvbox
    '';
    packages.myVimPackage = with vimPlugins; {
      start = [ vim-sneak vim-surround vim-easymotion gruvbox-community ];
      opt = [ ];
    };
  };
}
