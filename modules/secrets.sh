# modules/secrets.sh
# Loads machine-local secrets (API keys, tokens, …) into the environment from a
# file kept OUTSIDE this repository, so secret values are never tracked by git.
# Only this loader is committed — never the values themselves.
#
# Default location:  ~/.config/zsh/secrets.zsh   (override with $ZSH_SECRETS_FILE)
# Required perms:     600 — owner read/write only. The loader refuses to source
#                     the file if it is group- or world-readable.
#
# Format — plain exports, e.g.:
#     export OPENAI_API_KEY="sk-…"
#     export GITHUB_TOKEN="ghp_…"
#
# A documented, value-free template lives at modules/secrets.example.zsh.
# To get started:
#     mkdir -p ~/.config/zsh
#     cp ~/workspace/zsh/modules/secrets.example.zsh ~/.config/zsh/secrets.zsh
#     chmod 600 ~/.config/zsh/secrets.zsh
#     $EDITOR ~/.config/zsh/secrets.zsh

_zsh_load_secrets() {
    local file="${ZSH_SECRETS_FILE:-$HOME/.config/zsh/secrets.zsh}"
    [[ -r "$file" ]] || return 0

    # Refuse to load if anyone but the owner can read the file. Use zsh's stat
    # builtin so we don't spawn a process on every shell startup. st[1] is the
    # numeric st_mode; masking 0077 isolates the group/other permission bits.
    zmodload -F zsh/stat b:zstat 2>/dev/null
    local -a st
    if zstat -A st +mode "$file" 2>/dev/null && (( (st[1] & 0077) != 0 )); then
        print -ru2 -- "secrets.sh: refusing to load ${file/#$HOME/~} — permissions too open."
        print -ru2 -- "            run: chmod 600 \"${file/#$HOME/~}\""
        return 1
    fi

    source "$file"
}
_zsh_load_secrets
unset -f _zsh_load_secrets
