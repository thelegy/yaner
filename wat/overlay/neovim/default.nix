{ neovim, vimPlugins }:

neovim.override {
  configure = {
    customRC = ''
      " let mapleader=" "
      map <Space> \

      inoremap fd <Esc>
      vnoremap fd <Esc>

      set shiftwidth=2
      set expandtab
      set shiftround

      set smartindent
      filetype plugin indent on

      set wildmode=longest:full,full

      " Save with Ctrl-S (if file has changed)
      noremap <C-s> <Cmd>update<CR>

      nnoremap <C-p> <Cmd>Files<CR>

      set ignorecase
      set smartcase

      set number
      set relativenumber
      set mouse=a

      set clipboard=unnamed

      set inccommand=split

      let g:highlightedyank_highlight_duration = 200

      " NERDTree
      " Show hidden files by default
      let g:NERDTreeShowHidden = 1
      " Automaticaly close nvim if NERDTree is only thing left open
      autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
      " Toggle with Alt-b
      nnoremap <a-b> <Cmd>NERDTreeToggle<CR>

      let g:LanguageClient_serverCommands = {
        \ 'cpp': ['clangd', '--background-index',],
      \ }
      let g:LanguageClient_useVirtualText = "No"

      function SetLSPShortcuts()
        nnoremap <Leader>la <Cmd>call LanguageClient_workspace_applyEdit()<CR>
        nnoremap <Leader>lc <Cmd>call LanguageClient#textDocument_definition()<CR>
        nnoremap <Leader>ld <Cmd>call LanguageClient#textDocument_definition()<CR>
        nnoremap <Leader>le <Cmd>call LanguageClient#explainErrorAtPoint()<CR>
        nnoremap <Leader>lf <Cmd>call LanguageClient#textDocument_formatting()<CR>
        nnoremap <Leader>lh <Cmd>call LanguageClient#textDocument_hover()<CR>
        nnoremap <Leader>lm <Cmd>call LanguageClient_contextMenu()<CR>
        nnoremap <Leader>lr <Cmd>call LanguageClient#textDocument_rename()<CR>
        nnoremap <Leader>ls <Cmd>call LanguageClient_textDocument_documentSymbol()<CR>
        nnoremap <Leader>lt <Cmd>call LanguageClient#textDocument_typeDefinition()<CR>
        nnoremap <Leader>lx <Cmd>call LanguageClient#textDocument_references()<CR>

        set signcolumn=yes
      endfunction()

      augroup LSP
        autocmd!
        autocmd FileType cpp,c call SetLSPShortcuts()
      augroup END

      let g:deoplete#enable_at_startup = 1

      colorscheme gruvbox
    '';
    packages.myVimPackage = with vimPlugins; {
      start = [
        LanguageClient-neovim
        deoplete-nvim
        fzf-vim
        fzfWrapper
        gruvbox-community
        nerdtree
        vim-devicons
        vim-easymotion
        vim-highlightedyank
        vim-nix
        vim-sneak
        vim-surround
      ];
      opt = [ ];
    };
  };
}
