# modules/git.sh
# Helper features for git.

# gwt-add my-feature
# - New branch `my-feature` from `origin/main`
#
# gwt-add fix-1 dev-base
# - New branch `fix-1` from `dev-base`
#
# gwt-add experiment --upstream_current
# - New branch `experiment` from your current HEAD
gwt-add() {
    # 1. Check for arguments: Display help if empty
    if [[ $# -eq 0 ]]; then
        echo "Git Worktree Helper"
        echo "-------------------"
        echo "Usage: gwt-add <new-branch-name> [parent-branch] [--upstream_current]"
        echo ""
        echo "Options:"
        echo "  new-branch-name     The name of the new branch and folder."
        echo "  parent-branch       (Optional) Branch to derive from. Defaults to 'origin/main'."
        echo "  --upstream_current  Use the branch you are currently on as the parent."
        echo ""
        echo "Example:"
        echo "  gwt-add feature-login develop"
        return 0
    fi

    local NEW_BRANCH=""
    local PARENT_BRANCH="origin/main"
    local UPSTREAM_CURRENT=false
    local ARGS=()

    # 2. Parse Flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --upstream_current)
                UPSTREAM_CURRENT=true
                shift
                ;;
            *)
                ARGS+=("$1")
                shift
                ;;
        esac
    done

    # 3. Assign positional variables
    NEW_BRANCH="${ARGS[0]}"
    [[ -n "${ARGS[1]}" ]] && PARENT_BRANCH="${ARGS[1]}"

    # 4. Handle --upstream_current
    if [ "$UPSTREAM_CURRENT" = true ]; then
        PARENT_BRANCH=$(git branch --show-current)
        echo "➜ Using current branch '$PARENT_BRANCH' as parent."
    fi

    # 5. Get Git Root
    local GIT_ROOT
    GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        echo "Error: Not in a git repository."
        return 1
    fi

    # 6. Setup Path
    local WT_PATH="$GIT_ROOT/.worktrees/$NEW_BRANCH"

    # 7. Safety: check if .worktrees is ignored
    if ! git check-ignore -q "$GIT_ROOT/.worktrees/"; then
        echo "Warning: '$GIT_ROOT/.worktrees/' is not in your .gitignore."
        echo "You should add it to prevent Git from tracking your worktree folders."
    fi

    # 8. Execute
    echo "➜ Creating worktree: $WT_PATH"
    echo "➜ Branching '$NEW_BRANCH' from '$PARENT_BRANCH'..."
    
    git worktree add -b "$NEW_BRANCH" "$WT_PATH" "$PARENT_BRANCH"

    # 9. Completion
    if [[ $? -eq 0 ]]; then
        echo "Done! You can access it at: cd $WT_PATH"
    fi
}
