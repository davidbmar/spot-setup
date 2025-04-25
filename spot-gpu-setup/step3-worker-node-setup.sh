#!/usr/bin/env bash
set -euo pipefail

BASHRC="$HOME/.bashrc"
BACKUP="$BASHRC.bak.$(date +%Y%m%d-%H%M%S)"

echo "🔹 Backing up $BASHRC -> $BACKUP"
cp "$BASHRC" "$BACKUP"

# 1. Enable vi mode (only if not already present)
if ! grep -q "^set\ -o\ vi" "$BASHRC"; then
    echo "🔹 Adding 'set -o vi' to $BASHRC"
    printf "\n# Enable vi-style command-line editing\nset -o vi\n" >> "$BASHRC"
else
    echo "✔ 'set -o vi' already present"
fi

# 2. Add baby-blue prompt
PROMPT_MARKER="# >>> workernode prompt >>>"
if ! grep -q "$PROMPT_MARKER" "$BASHRC"; then
    cat >> "$BASHRC" <<'EOF'

# >>> workernode prompt >>>
# Baby-blue (bright cyan = 0;96) [workernode][dir] prompt
PS1='\[\e[0;96m\][workernode][\W]\[\e[0m\]\$ '
# <<< workernode prompt <<<
EOF
    echo "🔹 Added baby-blue prompt"
else
    echo "✔ workernode prompt already present"
fi

echo "✅ Done. Run 'source ~/.bashrc' or open a new shell to activate."
source ~/.bashrc
