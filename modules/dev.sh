# modules/dev.sh
# Basic configuration for development.

alias code="/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code"

# Bring the VS Code window for the current directory to the front
vcf() {
    local target_dir=${1:-$(pwd)}
    # Use the 'reuse-window' flag to ensure it targets the existing instance
    code --reuse-window "$target_dir"
    # Force macOS to bring VS Code to the foreground
    osascript -e 'tell application "Visual Studio Code" to activate'
}

alias vault="bun scripts/vault/vault.ts"
