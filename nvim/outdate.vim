syntax on
filetype plugin indent on


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

