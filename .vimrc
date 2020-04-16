set nocompatible              " required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" let Vundle manage Vundle, required
Plugin 'gmarik/Vundle.vim'

" Leader key
:let mapleader = " "

" Line numbering
set nu

" paste
vnoremap p pgvy
vnoremap P Pgvy

" split navigations
nnoremap <C-K> <C-W><C-J>
nnoremap <C-L> <C-W><C-K>
nnoremap <C-M> <C-W><C-L>
nnoremap <C-J> <C-W><C-H>

" UTF-8 encoding
set encoding=utf-8

" Autocomplete
Bundle 'Valloric/YouCompleteMe'
let g:ycm_autoclose_preview_window_after_completion=1
map <leader>g  :YcmCompleter GoToDefinitionElseDeclaration<CR>

" Python: Autoindent
Plugin 'vim-scripts/indentpython.vim'

" Python: Execute python
nmap <F5> <Esc>:wa<CR>:!clear;python %<CR>

" Latex
Plugin 'lervag/vimtex'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
