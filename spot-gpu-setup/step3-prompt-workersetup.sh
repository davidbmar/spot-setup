#!/usr/bin/env bash
set -euo pipefail

BASHRC="$HOME/.bashrc"
BACKUP="$BASHRC.bak.$(date +%Y%m%d-%H%M%S)"

echo "🔹 Backing up $BASHRC -> $BACKUP"
cp "$BASHRC" "$BACKUP"

# 1. Enable vi mode if missing
if ! grep -q "^set -o vi" "$BASHRC"; then
    echo "🔹 Adding 'set -o vi' to $BASHRC"
    printf "\n# Enable vi-style command-line editing\nset -o vi\n" >> "$BASHRC"
else
    echo "✔ 'set -o vi' already present"
fi

# 2. Add dark-blue dockerbuilder prompt if missing
PROMPT_MARKER="# >>> dockerbuilder prompt >>>"
if ! grep -q "$PROMPT_MARKER" "$BASHRC"; then
    cat >> "$BASHRC" <<'EOF'

# >>> dockerbuilder prompt >>>
# Dark blue (0;34) [dockerbuilder][dir] prompt
PS1='\[\e[0;34m\][dockerbuilder][\W]\[\e[0m\]\$ '
# <<< dockerbuilder prompt <<<
EOF
    echo "🔹 Added dark-blue dockerbuilder prompt"
else
    echo "✔ dockerbuilder prompt already present"
fi

echo "✅ Done. Reloading when appropriate…"

# 3. Safe auto-reload (only if sourced in an interactive shell)
if [[ "${BASH_SOURCE[0]}" != "$0" ]] && [[ -n "${PS1:-}" ]]; then
    set +u
    source "$BASHRC"
    set -u
    echo "🔄  ~/.bashrc reloaded in current shell."
else
    echo "ℹ︎  To apply changes now, run:  source ~/.bashrc"
fi

