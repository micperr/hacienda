#!/usr/bin/env zsh

if [ ! -d ~/.zprezto ]; then
  git clone --quiet --recursive https://github.com/micperr/prezto.git ~/.zprezto
  setopt EXTENDED_GLOB
  for rcfile in ${ZDOTDIR:-$HOME}/.zprezto/runcoms/^README.md(.N); do
    rcfile_dst=${ZDOTDIR:-$HOME}/.${rcfile:t}
    if [ ! -f ${rcfile_dst} ]; then
        ln -s ${rcfile} ${rcfile_dst}
    fi
  done
  sed --follow-symlinks -i "s/theme 'sorin'/theme 'steeef'/g" ${ZDOTDIR:-$HOME}/.zpreztorc
  cp ~/.zprezto/contrib/micper/os.zsh.dist ~/.zprezto/contrib/micper/os.zsh
  sed -i '/arch.zsh/ s/^# *//' ~/.zprezto/contrib/micper/os.zsh
fi
