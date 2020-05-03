#!/usr/bin/env bash
set -euo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

navigate_script="${CURRENT_DIR}/tmux-navigate.sh"
source "${navigate_script}"
tmux set-environment -g navigate_pane "${navigate_script}"

no_bindings=$(get_tmux_option @navigate-no-bindings) || no_bindings=0

set_normal_bindings() {
  tmux bind-key -n M-h  run-shell -b "#{navigate_pane} left"
  tmux bind-key -n M-j  run-shell -b "#{navigate_pane} down"
  tmux bind-key -n M-k  run-shell -b "#{navigate_pane} up"
  tmux bind-key -n M-l  run-shell -b "#{navigate_pane} right"
  tmux bind-key -n M-\\ run-shell -b "#{navigate_pane} back"
}

main() {
  if [[ "${no_bindings}" -ne 1 ]]; then
    set_normal_bindings
  fi
}
main
