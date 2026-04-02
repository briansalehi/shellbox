set number
set norelativenumber

set autoindent
set smartindent

set splitright
set splitbelow

set smarttab
set expandtab
set tabstop=4
set softtabstop=4
set shiftwidth=4

set mouse=

syntax on
filetype plugin indent on

set completeopt=menu,noselect

call plug#begin()

Plug 'https://github.com/vim-airline/vim-airline.git'

" File navigation and search
"Plug 'https://github.com/scrooloose/nerdtree'
Plug 'https://github.com/preservim/nerdtree'
"Plug 'https://github.com/junegunn/fzf.vim'
"Plug 'https://github.com/junegunn/fzf', { 'do': { -> fzf#install() } }

Plug 'https://github.com/tpope/vim-surround'
Plug 'https://github.com/tpope/vim-commentary'
"Plug 'https://github.com/s1n7ax/nvim-terminal'
Plug 'https://github.com/rafi/awesome-vim-colorschemes'
Plug 'https://github.com/preservim/tagbar'
Plug 'https://github.com/ethanholz/nvim-lastplace'
"Plug 'https://github.com/glepnir/dashboard-nvim'

" Code completion and snippets
"Plug 'https://github.com/Valloric/YouCompleteMe'
"Plug 'https://github.com/neoclide/coc.nvim', {'branch': 'release'}
"Plug 'https://github.com/SirVer/ultisnips'
"Plug 'https://github.com/honza/vim-snippets'
"Plug 'https://github.com/ms-jpq/coq_nvim'
"Plug 'https://github.com/nvim-lua/completion-nvim'

" Syntax highlighting and linting
"Plug 'https://github.com/dense-analysis/ale'

" Automatic method definition
"Plug 'https://github.com/octol/vim-cpp-enhanced-highlight'
"Plug 'https://github.com/Raimondi/delimitMate'

" Git integration
"Plug 'https://github.com/tpope/vim-fugitive'

"Plug 'https://github.com/dkarter/bullets.vim'
"Plug 'https://github.com/cdelledonne/vim-cmake'
Plug 'https://github.com/nvim-telescope/telescope.nvim'
Plug 'https://github.com/nvim-treesitter/nvim-treesitter'
Plug 'https://github.com/nvim-lua/plenary.nvim'
Plug 'https://github.com/sharkdp/fd'
"Plug 'https://github.com/neovim/nvim-lspconfig'
"Plug 'https://github.com/shime/vim-livedown'
"Plug 'https://github.com/szw/vim-maximizer'
"Plug 'https://github.com/csexton/trailertrash.vim'
Plug 'https://github.com/farmergreg/vim-lastplace'
"Plug 'https://github.com/puremourning/vimspector'
"Plug 'https://github.com/sakhnik/nvim-gdb'

Plug 'https://github.com/zivyangll/git-blame.vim'

call plug#end()

" COC configuration for autocompletion
let g:coc_global_extensions = ['coc-clangd', 'coc-snippets', 'coc-pairs', 'coc-tsserver']

" Ale settings for linting
let g:ale_linters = {'cpp': ['clang']}
let g:ale_fixers = {'cpp': ['clang-format']}
let g:ale_cpp_clang_executable = 'clang++'
let g:ale_cpp_clang_options = '-std=c++20'

" youcompleteme settings
let g:ycm_global_ycm_extra_conf = '~/.vim/.ycm_extra_conf.py'
let g:ycm_confirm_extra_conf = 0

" nerdtree
nnoremap <C-n> :NERDTreeToggle<CR>

let g:NERDTreeDirArrowExpandable="+"
let g:NERDTreeDirArrowCollapsible="-"

" tagbar
nnoremap <C-t> :Tagbar fjc<CR>

" nvim-lastplace
let g:lastplace_ignore = "gitcommit,gitrebase,svn,hgcommit"
let g:lastplace_ignore_buftype = "quickfix,nofile,help"
let g:lastplace_ignore_filetype = "gitcommit,gitrebase,svn,hgcommit"
let g:lastplace_open_folds = 1

" vim-livedown
nmap <leader>gm :LivedownToggle<CR>
let g:livedown_autorun = 0
let g:livedown_open = 1
let g:livedown_port = 1337
let g:livedown_browser = "firefox"

" vim-maximizer
noremap <C-w>m :MaximizerToggle<CR>

" trailertrash
nmap <leader>gt :TrailerTrim<CR>

" awesome-vim-colorschemes
" Brian's favorite color schemes:
"   koehler      (high performance)
"   molokai      (visually appealing)
"   sonokai      (sublime theme)
"   jellybeans   (easy for eyes less colors)
"   wombat256mod (easy for eyes more colors)
colorscheme jellybeans

set cursorline

let g:clang_user_options='|| exit 0'
let g:clang_use_library=1
set completeopt-=preview

let g:python3_host_prog = '/usr/bin/python3'

set encoding=utf-8
set fileencoding=utf-8

" airline
let g:airline_powerline_fonts = 1

" git-blame
let g:gitblame_display_virtual_text = 1
noremap <leader>gb :<C-u>call gitblame#echo()<CR>

