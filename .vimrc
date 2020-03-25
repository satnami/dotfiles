set nocompatible

set autoindent

set rtp+=~/.vim/bundle/Vundle.vim

call vundle#begin()
Plugin 'VundleVim/Vundle.vim'
Plugin 'godlygeek/csapprox'
Plugin 'ctrlpvim/ctrlp.vim'
Plugin 'git://git.wincent.com/command-t.git'
Plugin 'rstacruz/sparkup', {'rtp': 'vim/'}
Plugin 'vim-ruby/vim-ruby'
Plugin 'nelstrom/vim-textobj-rubyblock'
Plugin 'tpope/vim-fugitive'
Plugin 'tpope/vim-endwise'
Plugin 'tpope/vim-markdown'
Plugin 'tpope/vim-surround'
Plugin 'tpope/vim-sensible'
Plugin 'tpope/vim-ragtag'
Plugin 'henrik/vim-indexed-search'
Plugin 'scrooloose/nerdtree'
Plugin 'Xuyuanp/nerdtree-git-plugin'
Plugin 'scrooloose/nerdcommenter'
Plugin 'scrooloose/syntastic'
Plugin 'AndrewRadev/splitjoin.vim'
Plugin 'michaeljsmith/vim-indent-object'
Plugin 'chrisbra/csv.vim'
Plugin 'kana/vim-textobj-user'
Plugin 'bling/vim-airline'
Plugin 'morhetz/gruvbox'
Plugin 'terryma/vim-multiple-cursors'
Plugin 'junegunn/goyo.vim'
Plugin 'itchyny/lightline.vim'
Plugin 'easymotion/vim-easymotion'
Plugin 'flazz/vim-colorschemes'
Plugin 'dracula/vim'
Plugin 'sheerun/vim-polyglot'
call vundle#end()

set backspace=indent,eol,start

filetype on
filetype plugin on
filetype indent on

autocmd FileType ruby compiler ruby


set wildmenu
set wildmode=list:longest
set wildignore=*.dll,*.o,*.obj,*.bak,*.exe,*.pyc,*.swp,*.jpg,*.gif,*.png
set lz
set autoindent
set cursorcolumn
set cursorline
set number
set ruler
set showcmd
set showmode

set list
set listchars=tab:▷⋅,trail:⋅,nbsp:⋅

set incsearch
set hlsearch

set wrap
set linebreak

set noswapfile

syntax on
color dracula