#!/usr/bin/env bash
# Shared helper library for Android QA Audit scripts

REPO_ROOT="/home/kornella/Dha-Anywaa-application"
AUDIT_DIR="$REPO_ROOT/audit"
SCRIPTS_DIR="$REPO_ROOT/scripts"

# Write-path guard — abort if target is outside audit/ or scripts/
check_write_path() {
    local target="$1"
    # Resolve absolute path if relative
    if [[ "$target" != /* ]]; then
        target="$REPO_ROOT/$target"
    fi
    case "$target" in
        "$AUDIT_DIR"/*|"$SCRIPTS_DIR"/*) ;;
        *) echo "ABORT: write to '$target' is outside audit/ and scripts/" >&2; exit 2 ;;
    esac
}

# ripgrep with grep fallback
rg_or_grep() {
    if command -v rg >/dev/null 2>&1; then
        rg -n "$@"
    else
        grep -rn "$@"
    fi
}

# Logging helpers
log()  { echo "[audit] $*"; }
die()  { echo "[audit] ERROR: $*" >&2; exit 1; }

export REPO_ROOT AUDIT_DIR SCRIPTS_DIR
