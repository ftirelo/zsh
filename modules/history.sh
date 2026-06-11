# modules/history.sh
# History configuration for zsh.

# Zsh needs these to remember your previous commands across sessions
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY  # Append to history file rather than replace
setopt SHARE_HISTORY   # Share history across all open terminal tabs

# Makes the Up/Down arrows search through history for what you've typed.
# The *-end variants run the same prefix search but leave the cursor at the
# end of the recalled command instead of at column 0.
autoload -Uz history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^[[A" history-beginning-search-backward-end
bindkey "^[[B" history-beginning-search-forward-end
