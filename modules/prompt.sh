# modules/prompt.sh
# Configure terminal prompt.

# Load VCS (Version Control System) info
autoload -Uz vcs_info
setopt PROMPT_SUBST

# Configure vcs_info for Git
# Enable 'check-for-changes' to detect staged (+) and unstaged (*) edits
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' unstagedstr "%F{214}*%f"  # Nord Yellow (*)
zstyle ':vcs_info:git:*' stagedstr "%F{143}+%f"    # Nord Green (+)

# Format the branch display
# %b = branch name | %u = unstaged | %c = staged
zstyle ':vcs_info:git:*' formats '[%b%u%c] '
zstyle ':vcs_info:git:*' actionformats '[%b|%a%u%c] '

# Define Nord Colors
COLOR_DIR="%F{75}"    # Nord Blue
COLOR_RESET="%f"

# Update prompt before every command
precmd() { vcs_info }

# The Final Prompt
# [%b%u%c] = [branch*+] | %1~ = directory | %# = % symbol
PROMPT='${vcs_info_msg_0_}${COLOR_DIR}%1~${COLOR_RESET} %B%#%b '

