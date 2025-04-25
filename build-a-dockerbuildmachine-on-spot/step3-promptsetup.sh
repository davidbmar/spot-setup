#!/usr/bin/env bash
set -euo pipefail

BASHRC="$HOME/.bashrc"
BACKUP="$BASHRC.bak.$(date +%Y%m%d-%H%M%S)"

echo "🔹 Backing up $BASHRC -> $BACKUP"
cp "$BASHRC" "$BACKUP"

# 1. Enable vi mode
if ! grep -q "^set\ -o\ vi" "$BASHRC"; then
    printf "\n# Enable vi-style command-line editing\nset -o vi\n" >> "$BASHRC"
fi

# 2. Add dark-blue [dockerbuilder][dir] prompt
PROMPT_MARKER="# >>> dockerbuilder prompt >>>"
if ! grep -q "$PROMPT_MARKER" "$BASHRC"; then
    cat >> "$BASHRC" <<'EOF'

# >>> dockerbuilder prompt >>>
PS1='\[\e[0;34m\][dockerbuilder][\W]\[\e[0m\]\$ '
# <<< dockerbuilder prompt <<<
EOF
fi

echo "✅ Done.  Reloading configuration when appropriate…"

###############################################################################
# Safe auto-reload:
# – Only runs when the *parent* shell is interactive *and* the script was
#   executed via “source ./setup_prompt.sh” or “. ./setup_prompt.sh”.
###############################################################################
if [[ "${BASH_SOURCE[0]}" != "$0" ]] && [[ -n "${PS1:-}" ]]; then
    # Temporarily disable “unset variable” checks to avoid PS1 reference issues
    set +u
    source "$BASHRC"
    set -u
    echo "🔄  ~/.bashrc reloaded in current shell."
else
    echo "ℹ︎  Open a new terminal or run:  source ~/.bashrc"
fi

