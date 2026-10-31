# shellcheck shell=bash
# checkout.sh: shared by the scripts that start Emacs on a checkout.
#
# Sourced, not run, by bin/start-check, bin/screenshot, and
# test/gui-ert.
#
# Author: Tim Jim
# Date: 2026-10-31

# Stop unless $1 (resolved from the path given as $2) is the top of a
# git checkout holding early-init.el, so a mistyped path can't pass by
# starting Emacs on some other folder.
require_checkout() {
    local top
    top=$(git -C "$1" rev-parse --show-toplevel 2>/dev/null)
    if [[ -z $1 || $top != "$1" ]]; then
        echo "FAIL: not a git checkout: $2"
        exit 1
    fi
    if [[ ! -f $1/early-init.el ]]; then
        echo "FAIL: not a config checkout (no early-init.el): $2"
        exit 1
    fi
}
