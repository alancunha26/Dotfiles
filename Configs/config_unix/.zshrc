export ZSH="$HOME/.oh-my-zsh"

# Setup theme
ZSH_THEME="robbyrussell"

# Setup plugins
plugins=(git zsh-autosuggestions zsh-vi-mode)
source $ZSH/oh-my-zsh.sh

# Setup zsh vi keybinds
ZVM_VI_INSERT_ESCAPE_BINDKEY=jk

# Startup Starship
eval "$(starship init zsh)"

# Startup ASDF
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

# Set JAVA_HOME
. ~/.asdf/plugins/java/set-java-home.zsh

# Set PNPM_HOME
export PNPM_HOME="/home/alancunha/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Aliases
alias nnvim="NVIM_APPNAME=nvim-new nvim"

# Run fastfetch
fastfetch


