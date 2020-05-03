#!/usr/bin/env bash
#
# Intelligently navigate tmux panes and Vim splits using the same keys.
# This also supports SSH tunnels where Vim is running on a remote host.
#
#      +-------------+------------+-----------------------------+
#      | inside Vim? | is Zoomed? | Action taken by key binding |
#      +-------------+------------+-----------------------------+
#      | No          | No         | Focus directional tmux pane |
#      | No          | Yes        | Nothing: ignore key binding |
#      | Yes         | No         | Seamlessly focus Vim / tmux |
#      | Yes         | Yes        | Focus directional Vim split |
#      +-------------+------------+-----------------------------+
#
# See https://sunaku.github.io/tmux-select-pane.html for documentation.
set -euo pipefail

get_tmux_option() { tmux show-option -gqv "$@" | grep . ;}

timeout=$(get_tmux_option '@navigate-timeout') || timeout=0.05 # seconds
vim_navigation_timeout=$timeout;
pane_title="$(tmux display -p '#{q:pane_title}')";
pane_current_command="$(tmux display -p '#{q:pane_current_command}')";
pane_is_zoomed() {
  test "$(tmux display -p '#{window_zoomed_flag}')" -eq 1;
};
pane_title_changed() {
  test "$pane_title" != "$(tmux display -p '#{q:pane_title}')";
};
command_is_vim() {
  case "${1%% *}" in
    (vi|?vi|vim*|?vim*|view|?view|vi??*) true ;;
    (*) false ;;
  esac;
};
pane_contains_vim() {
  case "$pane_current_command" in
    (git|*sh) command_is_vim "$pane_title" ;;
    (*) command_is_vim "$pane_current_command" ;;
  esac;
};
pane_contains_neovim_terminal() {
  case "$pane_title" in
    (nvim?term://*) true ;;
    (*) false ;;
  esac;
};
navigate() {
  tmux_navigation_command=$1;
  vim_navigation_command=$2;
  vim_navigation_only_if=${3:-true};
  if pane_contains_vim && eval "$vim_navigation_only_if"; then
    if pane_contains_neovim_terminal; then
      tmux send-keys C-\\ C-n;
    fi;
    eval "$vim_navigation_command";
    if ! pane_is_zoomed; then
      sleep $vim_navigation_timeout; # wait for Vim to change title;
      if ! pane_title_changed; then
        tmux send-keys BSpace;
        eval "$tmux_navigation_command";
      fi;
    fi;
  elif ! pane_is_zoomed; then
    at_edge_script=$(tmux display-message -p "#{at_edge}")
    if [[ -x ${at_edge_script} ]]; then
      # get the L/R/D/U direction
      edge_direction="${tmux_navigation_command: -1}"
      if "$at_edge_script" "$edge_direction"; then
        exit 0
      fi
    fi
    eval "$tmux_navigation_command";
  fi;
};

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  case "$1" in
    left )
      navigate 'tmux select-pane -L'  'tmux send-keys C-w h' ;;
    down )
      navigate 'tmux select-pane -D'  'tmux send-keys C-w j' ;; 
    up )
      navigate 'tmux select-pane -U'  'tmux send-keys C-w k' ;;
    right )
      navigate 'tmux select-pane -R'  'tmux send-keys C-w l' ;;
    back )
      navigate 'tmux select-pane -l || tmux select-pane -t1' 'tmux send-keys C-w p' 'pane_is_zoomed' ;;
    "" )
      printf "No argument provided\n" ;;
    * )
      printf "Unexpected input '%s'\n" "$1" ;;
  esac
fi
