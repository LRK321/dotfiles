#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
IS_MACOS=false
IS_CONTAINER=false

[[ "$OSTYPE" == darwin* ]] && IS_MACOS=true
[[ -f /.dockerenv ]] || [[ -n "${REMOTE_CONTAINERS:-}" ]] || [[ -n "${CODESPACES:-}" ]] && IS_CONTAINER=true

# --- Backup existing files (before symlinking) ---
backup_if_exists() {
    local target="$1"
    if [[ -e "$target" ]] && [[ ! -L "$target" ]]; then
        mkdir -p "$BACKUP_DIR"
        cp -a "$target" "$BACKUP_DIR/"
        echo "  Backed up $(basename "$target") → $BACKUP_DIR/"
    fi
}

# --- Oh My Zsh + plugins + theme (install if missing) ---
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo "Installing Oh My Zsh..."
    RUNZSH=no KEEP_ZSHRC=yes sh -c \
      "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

[[ -d "$ZSH_CUSTOM/themes/powerlevel10k" ]] || \
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
[[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]] || \
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
[[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]] || \
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
[[ -d "$ZSH_CUSTOM/plugins/zsh-nvm" ]] || \
    git clone --depth=1 https://github.com/lukechilds/zsh-nvm "$ZSH_CUSTOM/plugins/zsh-nvm"

# --- Symlink shared config files (backup originals first) ---
SYMLINKS=(
    "shell/.zshrc:$HOME/.zshrc"
    "shell/.p10k.zsh:$HOME/.p10k.zsh"
    "shell/.inputrc:$HOME/.inputrc"
    "git/.gitconfig:$HOME/.gitconfig"
    "git/.gitignore_global:$HOME/.gitignore_global"
    "tmux/.tmux.conf:$HOME/.tmux.conf"
)

for entry in "${SYMLINKS[@]}"; do
    src="${DOTFILES_DIR}/${entry%%:*}"
    dst="${entry##*:}"
    backup_if_exists "$dst"
    ln -sf "$src" "$dst"
done

# --- Claude config ---
mkdir -p "$HOME/.claude"
backup_if_exists "$HOME/.claude/settings.json"
backup_if_exists "$HOME/.claude/statusline-command.sh"
ln -sf "$DOTFILES_DIR/claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"
chmod +x "$DOTFILES_DIR/claude/statusline-command.sh"

# Claude settings: merge base + platform-specific
if $IS_MACOS && [[ -f "$DOTFILES_DIR/claude/settings.macos.json" ]]; then
    # On macOS: combine base settings with macOS hooks (jq merge)
    if command -v jq &>/dev/null; then
        jq -s '.[0] * .[1]' \
            "$DOTFILES_DIR/claude/settings.json" \
            "$DOTFILES_DIR/claude/settings.macos.json" \
            > "$HOME/.claude/settings.json"
    else
        cp "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json"
    fi
else
    # In container: use base settings only (no afplay)
    ln -sf "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json"
fi

# --- macOS-specific setup ---
if $IS_MACOS; then
    # .zprofile with conda/JetBrains
    backup_if_exists "$HOME/.zprofile"
    ln -sf "$DOTFILES_DIR/shell/.zprofile.macos" "$HOME/.zprofile"

    # macOS git overrides (signing key, credential helpers)
    ln -sf "$DOTFILES_DIR/git/.gitconfig.macos" "$HOME/.gitconfig.macos"
fi

# --- Linux/WSL-specific setup ---
if ! $IS_MACOS && ! $IS_CONTAINER; then
    backup_if_exists "$HOME/.zprofile"
    ln -sf "$DOTFILES_DIR/shell/.zprofile.linux" "$HOME/.zprofile"
fi

# --- Summary ---
if [[ -d "$BACKUP_DIR" ]]; then
    echo "[dotfiles] Backups saved to $BACKUP_DIR"
fi
echo "[dotfiles] Installation complete ($OSTYPE)"
