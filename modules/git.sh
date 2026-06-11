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
    NEW_BRANCH="${ARGS[1]}"
    [[ -n "${ARGS[2]}" ]] && PARENT_BRANCH="${ARGS[2]}"

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

gcdw() {
  local name="$1"
  local wt_path
  wt_path=$(git worktree list --porcelain | awk -v n="$name" '
    /^worktree / { p = $2 }
    /^branch / {
      sub("refs/heads/", "", $2)
      if ($2 == n || p ~ n"$") { print p; exit }
    }
  ')
  if [[ -n "$wt_path" ]]; then
    cd "$wt_path"
  else
    echo "No worktree matching: $name" >&2
    return 1
  fi
}

_gcdw() {
  local -a worktrees
  worktrees=(${(f)"$(git worktree list 2>/dev/null | awk '{print $1}' | xargs -n1 basename)"})
  compadd -a worktrees
}
compdef _gcdw gcdw

# gsync — sync allowlisted local checkouts with their remotes.
#
# For every repo on the allowlist (or just the ones named as arguments) this
# runs depot_tools' `git rebase-update`, which fetches each remote and rebases
# every local branch onto its upstream.
#
# Merge conflicts are handled with `--keep-going`: a branch that can't be
# cleanly rebased has its rebase aborted — so that branch is left exactly as it
# was — and the remaining branches are still updated. The untouched branches are
# listed at the end so you know what to resolve by hand.
#
# If `git rebase-update` finishes with no branch checked out (HEAD detached,
# e.g. every local branch was merged and cleaned up), gsync checks out `main`.
#
# Once a repo settles on `main`, gsync runs `npm install` for it — but only when
# the sync changed the lockfile (or `node_modules` is missing). Node projects
# whose dependencies didn't move, and checkouts left on a feature branch, are
# untouched.
#
# Usage:
#   gsync                  # sync the whole allowlist
#   gsync orrery lift-api  # sync only these (must be on the allowlist)
#
# Override the search root with GSYNC_ROOT; edit GSYNC_REPOS for the allowlist.
GSYNC_ROOT="${GSYNC_ROOT:-$HOME/workspace}"
GSYNC_REPOS=(zsh gmail-filters lift-api personal-tracking orrery)

# _gsync-deps-id <repo-dir>
# Blob id of the main branch's npm manifest, used to detect dependency changes
# across a sync. Prefers package-lock.json (what `npm install` resolves from) and
# falls back to package.json. Empty when main has neither — i.e. not a Node repo.
_gsync-deps-id() {
    local dir="$1" id
    id="$(git -C "$dir" rev-parse refs/heads/main:package-lock.json 2>/dev/null)"
    [[ -n "$id" ]] || id="$(git -C "$dir" rev-parse refs/heads/main:package.json 2>/dev/null)"
    print -r -- "$id"
}

# _gsync-maybe-npm-install <repo-dir> <deps-id-before>
# Install npm dependencies for the main checkout when the sync changed them (or
# they were never installed). No-op for non-Node repos and for checkouts left on
# a branch other than main.
_gsync-maybe-npm-install() {
    local dir="$1" deps_before="$2"
    local name="${dir:t}"

    # Only the primary checkout (on main) gets dependencies installed.
    [[ "$(git -C "$dir" branch --show-current)" == "main" ]] || return 0

    # Not a Node project — nothing to install.
    [[ -f "$dir/package.json" ]] || return 0

    # Needed when the manifest moved during the sync, or nothing is installed yet.
    local deps_after
    deps_after="$(_gsync-deps-id "$dir")"
    [[ "$deps_before" != "$deps_after" || ! -d "$dir/node_modules" ]] || return 0

    if ! command -v npm >/dev/null 2>&1; then
        echo "    Warning: dependencies changed but npm is not installed."
        return 0
    fi

    echo "    ➜ Installing npm dependencies ..."
    local nout
    if nout="$(cd "$dir" && npm install 2>&1)"; then
        echo "    ➜ npm dependencies installed."
    else
        echo "    Warning: npm install failed in $name:"
        print -r -- "$nout" | sed 's/^/    /'
    fi
}

# _gsync-one <repo-dir>
# Sync a single checkout. Returns 1 if any branch was left untouched.
_gsync-one() {
    local dir="$1"
    local name="${dir:t}"

    if ! git -C "$dir" rev-parse --git-dir >/dev/null 2>&1; then
        echo "Warning: skipping $name — not a git repository ($dir)"
        return 0
    fi

    echo "➜ Syncing $name ..."

    # Fingerprint main's dependency manifest before the sync so we can tell
    # afterward whether `git rebase-update` pulled in any dependency changes.
    local deps_before
    deps_before="$(_gsync-deps-id "$dir")"

    # `--keep-going` aborts a conflicting branch's rebase (leaving it untouched)
    # and carries on, instead of stopping at the first conflict.
    local out
    out="$(cd "$dir" && git rebase-update --keep-going 2>&1)"
    [[ -n "$out" ]] && print -r -- "$out" | sed 's/^/    /'

    # The branches rebase-update reported as not cleanly rebased. The array
    # literal context naturally drops the empty result when there were none.
    local -a failed
    failed=( ${(f)"$(print -r -- "$out" | awk '
        /could not be cleanly rebased:/ { grab = 1; next }
        grab && /^  / { print $1; next }
        grab { grab = 0 }
    ')"} )

    # Land on main if rebase-update left HEAD detached (no current branch).
    if [[ -z "$(git -C "$dir" branch --show-current)" ]]; then
        if git -C "$dir" checkout main >/dev/null 2>&1; then
            echo "    ➜ No branch was checked out; switched to main."
        else
            echo "    Warning: no branch checked out and could not switch to main."
        fi
    fi

    # Refresh dependencies if the sync moved them (main checkout only).
    _gsync-maybe-npm-install "$dir" "$deps_before"

    if (( ${#failed} )); then
        echo "    Left untouched (conflicts): ${failed[*]}"
        return 1
    fi
    echo "    Up to date."
    return 0
}

gsync() {
    local -a targets
    if (( $# )); then
        local arg
        for arg in "$@"; do
            if (( ${GSYNC_REPOS[(Ie)$arg]} )); then
                targets+=("$arg")
            else
                echo "Warning: $arg is not on the gsync allowlist; skipping."
            fi
        done
    else
        targets=("${GSYNC_REPOS[@]}")
    fi
    (( ${#targets} )) || { echo "Nothing to sync."; return 0; }

    local -a problems
    local repo
    for repo in "${targets[@]}"; do
        _gsync-one "$GSYNC_ROOT/$repo" || problems+=("$repo")
        echo
    done

    echo "---"
    if (( ${#problems} )); then
        echo "Synced with conflicts in: ${problems[*]}"
        echo "Their conflicting branches were left untouched — resolve them by hand."
        return 1
    fi
    echo "All repos synced cleanly."
    return 0
}

# Tab-complete gsync with the allowlisted repo names.
_gsync() { compadd -a GSYNC_REPOS }
compdef _gsync gsync
