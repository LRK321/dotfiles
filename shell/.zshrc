# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-nvm web-search copyfile)
source $ZSH/oh-my-zsh.sh

# --- macOS-only ---
if [[ "$OSTYPE" == darwin* ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    export PATH="$HOME/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/local/sbin:/usr/local/opt/openssl@3/bin:$PATH"
    export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
    export LDFLAGS="-L/usr/local/opt/openssl/lib"
    export CPPFLAGS="-I/usr/local/opt/openssl/include"
    export PKG_CONFIG_PATH="/usr/local/opt/openssl/lib/pkgconfig"
    [ -f "$HOME/.ghcup/env" ] && . "$HOME/.ghcup/env"
fi

# --- Shared ---
export HISTSIZE=10000
export SAVEHIST=10000
setopt SHARE_HISTORY APPEND_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE

export GIT_AUTHOR_NAME="Lasse Kurz"
export GIT_COMMITTER_NAME="Lasse Kurz"

alias sha256sum='shasum --algorithm 256'
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
unsetopt BEEP

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
