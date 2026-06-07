# modules/secrets.example.zsh
#
# TEMPLATE ONLY — this file is committed for documentation. Keep it free of any
# real values. Your actual secrets live OUTSIDE this repo and are never tracked.
#
# Set up your real secrets file (one-time):
#     mkdir -p ~/.config/zsh
#     cp ~/workspace/zsh/modules/secrets.example.zsh ~/.config/zsh/secrets.zsh
#     chmod 600 ~/.config/zsh/secrets.zsh
#     $EDITOR ~/.config/zsh/secrets.zsh
#
# It is loaded automatically on shell startup by modules/secrets.sh.
# Override the location with $ZSH_SECRETS_FILE if you keep it elsewhere.
#
# Add one `export` per secret, then `exec zsh` (or open a new shell) to load it:

# export OPENAI_API_KEY="sk-…"
# export ANTHROPIC_API_KEY="sk-ant-…"
# export GITHUB_TOKEN="ghp_…"

# ─────────────────────────────────────────────────────────────────────────────
# ### Test-harness env vars (shell, not `.env.local`)
#
# These are read straight from the **shell environment** by the CLI / seed
# script — the `triage` CLI and `seed-inbox` do **not** load `.env.local` (only
# `npx convex dev` and Next.js do). Put them in your shell profile (`~/.zshrc`)
# or pass them inline before the command. See [test-account.md](test-account.md).
#
# | Variable                           | Example                           | Used by                                                                                                                         |
# | :--------------------------------- | :-------------------------------- | :------------------------------------------------------------------------------------------------------------------------------ |
# | `TRIAGE_BROWSER_APP`               | `Google Chrome Dev`               | `triage auth login` (macOS) — open sign-in in this browser vs the OS default                                                    |
# | `TRIAGE_BROWSER_PROFILE`           | `Profile 1`                       | `triage auth login` (macOS) — Chrome profile **directory** name (`chrome://version` → "Profile Path"); also used by `seed:auth` |
# | `TRIAGE_SEED_GOOGLE_CLIENT_ID`     | `<id>.apps.googleusercontent.com` | `seed-inbox` — dedicated **Desktop** OAuth client (gmail.modify); see [test-account.md](test-account.md) §5                     |
# | `TRIAGE_SEED_GOOGLE_CLIENT_SECRET` | `<secret>`                        | `seed-inbox` — secret for that OAuth client                                                                                     |
#
# export TRIAGE_BROWSER_APP="Google Chrome Dev"
# export TRIAGE_BROWSER_PROFILE="Profile 1"
# export TRIAGE_SEED_GOOGLE_CLIENT_ID="<id>.apps.googleusercontent.com"
# export TRIAGE_SEED_GOOGLE_CLIENT_SECRET="<secret>"
