#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${CURRENT_DIR}/tmux-navigate.sh"

no_bindings=$(get_tmux_option @navigate-no-bindings) || no_bindings=0

set_normal_bindings() {
  tmux bind-key -n M-h  run-shell -b "$CURRENT_DIR/tmux-navigate.sh left"
  tmux bind-key -n M-j  run-shell -b "$CURRENT_DIR/tmux-navigate.sh down"
  tmux bind-key -n M-k  run-shell -b "$CURRENT_DIR/tmux-navigate.sh up"
  tmux bind-key -n M-l  run-shell -b "$CURRENT_DIR/tmux-navigate.sh right"
  tmux bind-key -n M-\\ run-shell -b "$CURRENT_DIR/tmux-navigate.sh back"
}

main() {
  if [[ "${no_bindings}" -ne 1 ]]; then
    set_normal_bindings
  fi
}
main
