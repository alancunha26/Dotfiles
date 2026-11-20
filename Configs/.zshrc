export ZSH="$HOME/.oh-my-zsh"


# Setup theme
ZSH_THEME="robbyrussell"

# Setup plugins
# plugins=(git zsh-autosuggestions zsh-vi-mode direnv)
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

# Postgres path
# export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"

# eza as ls (oh-my-zsh's l/la/ll call ls, so they use it too)
if command -v eza >/dev/null; then
  alias ls='eza --icons=auto --group-directories-first'
  alias lt='ls --tree --level=2'
fi

# Startup zoxide as cd
eval "$(zoxide init zsh --cmd cd)"

# Run fastfetch. The cat logo (a GIF kitty plays, 56 columns at full size) shrinks to leave the
# info boxes their ~56 columns plus padding, and is left out when under 20 columns would remain.
# Rows are about 0.31 × columns: the art is 56×38 pixels and kitty's cells here are 9×20 px.
() {
  local w=$(( COLUMNS - 61 < 56 ? COLUMNS - 61 : 56 ))
  if (( w >= 20 )); then
    fastfetch --logo-width $w --logo-height $(( (w * 31 + 99) / 100 ))
  else
    fastfetch --logo-type none
  fi
}
