#!/usr/bin/env bash
# shellcheck disable=SC1090
set -o errexit
set -o nounset

# Sorry, Windows is not supported forever
OS=$(uname -s)
if [[ "${OS}" = "SunOS" ]] ; then
  SYSTEM='Solaris'
elif [[ "${OS}" = "Darwin" ]] ; then
  SYSTEM='Macos'
elif [[ "${OS}" = "Linux" ]] ; then
  if [[ -f /etc/debian_version ]] ; then
    SYSTEM='Debian'
  elif [[ -f /etc/redhat-release ]] ; then
    SYSTEM='RedHat'
  else
    SYSTEM='Linux'
  fi
else
  SYSTEM=""
fi

if [[ -z "${SYSTEM}" ]]; then
  echo 'The system is not supported now.' >&2
  exit 2;
fi


has() {
  local condition="$1"
  local value="$2"

  if [ "$condition" == "not" ]; then
    shift 1
    ! has "${@}"
    return $?
  fi

  case "$condition" in
    command)
      [[ -x "$(command -v "$value")" ]] && return 0;;
  esac > /dev/null

  return 1
}

_install_build_essential_Macos() {
  if has not command brew ; then
    echo 'To install homebrew'
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi
}

_install_build_essential() {
  echo "[_install_build_essential_${SYSTEM}]"
  _install_build_essential_${SYSTEM}

  if has not command git ; then
    echo 'To install git'
    _install_git_${SYSTEM}
  fi

  if has not command curl ; then
    echo 'To install curl'
    _install_curl
  fi

  if has not command rvm ; then
    echo 'To install rvm and ruby'
    _install_rvm
  fi

  if has not command python ; then
    echo 'To install python'
    _install__python_${SYSTEM}
  fi

  # special command nvm
  if command -v nvm != 'nvm' ; then
    echo 'To install nvm and node'
  fi
}

_install_git_Macos() {
  brew install git
}

_install_curl() {
  git clone https://github.com/curl/curl.git ~/Src/curl
  ./configure
  make
  make install
}

_install_rvm() {
  gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
  curl -sSL https://get.rvm.io | bash -s stable --ruby

  rvm install 2 --verify-downloads
  rvm --default use 2
}

_install_python() {

}

_install_nvm() {
  export NVM_DIR="$HOME/.nvm"
  git clone https://github.com/creationix/nvm.git "$NVM_DIR"
  cd "$NVM_DIR"
  git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" origin`
  cd -
  . "$NVM_DIR/nvm.sh"

  nvm install node
  nvm use node
}

_bootstrap_common() {
  echo '[Bootstrap in common]'

  echo 'To mkdir -p'
    mkdir -p ~/{Temp,Src,Workspace,Presentations,Design,Doc,Public,Pictures,Downloads}
    mkdir -p ~/.sshrc.d

  _install_build_essential

  if [[ ! -d ~/.bash_it ]] ; then
    echo 'To download bash_it'
    git clone --depth 1 https://github.com/Bash-it/bash-it.git ~/.bash_it
    ~/.bash_it/install.sh --no-modify-config
    ./bash_it/reset.sh
  fi

  _install_ruby
  _install_python
  _install_node

  if [[ ! -d ~/dotfiles ]] ; then
    echo 'To download my dotfiles'
    git clone --depth 1 --recursive git@github.com:adoyle-h/dotfiles.git ~/dotfiles
    # ~/dotfiles/install
  fi

  if [[ ! -d ~/dotfiles/secrets ]] ; then
    echo 'To download my secrets'
    # git clone --depth 1  ~/dotfiles/secrets
  fi

  if [[ ! -d ~/dotfiles/cheat ]] ; then
    echo 'To download my cheatsheet'
    git clone --depth 1 git@github.com:adoyle-h/my-command-cheat.git ~/dotfiles/cheat
  fi

  if [[ ! -d ~/dotfiles/nvim ]] ; then
    echo 'To download my nvim configuration'
    git clone --depth 1 git@github.com:adoyle-h/neovim-config.git ~/dotfiles/nvim
  fi

  if has not command fzf ; then
    echo 'To install fzf'
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install
  fi

  if has not command cheat ; then
    echo 'To install cheat'
    pip install cheat
  fi

  if [[ ! -d ~/.cd/core ]] ; then
    echo 'To download https://github.com/spencertipping/cd.git'
    git clone --depth 1 https://github.com/spencertipping/cd.git ~/.cd/core
  fi

  if has not command grip ; then
    echo 'To install grip'
    pip install grip
  fi

  ./install

  echo '[Done] Bootstrap in common'
}

_bootstrap_Macos() {
  brew bundle install

  echo '[Done] Bootstrap in macos'
}

_bootstrap_linux() {
  echo '[Done] Bootstrap in linux'
}


_bootstrap_common
echo "[Bootstrap in $SYSTEM]"
_bootstrap_$SYSTEM

unset -f has _bootstrap_common _bootstrap_macos _bootstrap_linux
unset -v SYSTEM OS

set +o errexit
set +o nounset
source ~/.bashrc
