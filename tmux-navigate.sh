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
PS4=':${LINENO}+'
set -x

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
  [[ "$pane_title" == "nvim\ term://"* ]]
};
navigate() {
  tmux_navigation_command=$1;
  vim_navigation_command=$2;
  vim_navigation_only_if=${3:-true};

  # get the L/R/D/U direction
  edge_direction="${tmux_navigation_command: -1}"
  at_edge_script=$(tmux display-message -p "#{at_edge}")
  
  tmux set-option -g @navigate-reenable-wrap 1

  on_an_edge=0
  if [[ "$(get_tmux_option '@navigate-reenable-wrap')" -eq 1 ]]; then
    if [[ "LDUR" == *"$edge_direction"* ]] && [[ -x ${at_edge_script} ]]; then
      if "$at_edge_script" "$edge_direction"; then
        on_an_edge=1
      fi
    fi
  fi
  if pane_contains_vim && eval "$vim_navigation_only_if"; then
    if pane_contains_neovim_terminal; then
      # Being in insert-terminal-mode causes the title string to not be
      # updated. This is presumably so that program inside the terminal can set
      # the title to something itself.
      tmux send-keys C-\\ C-n;
    fi;
    if [[ "$pane_title" == *"mode:i"* ]]; then
      # enter insert-normal mode for one command to allow a movement
      tmux send-keys 'C-o'
    fi
    eval "$vim_navigation_command";
    if ! pane_is_zoomed; then
      sleep $vim_navigation_timeout; # wait for Vim to change title;
      if ! pane_title_changed; then
        tmux send-keys BSpace;
        eval "$tmux_navigation_command";
      fi;
    fi;
  elif ! pane_is_zoomed; then
    # Skip edge detection if the action is "back"
    if [[ "LDUR" == *"$edge_direction"* ]] && [[ -x ${at_edge_script} ]] && [[ ! "$(get_tmux_option '@navigate-reenable-wrap')" -eq 1 ]]; then
      # `if-shell` can't be used for this e.g.
      #   bind-key -T root M-h if-shell -b "! #{at_edge} L" "run-shell '#{navigate_pane} left'"
      # because at_edge doesn't know about vim.
      if "$at_edge_script" "$edge_direction"; then
        exit 0
      fi
    fi
    eval "$tmux_navigation_command";
  fi;
  if [[ "$on_an_edge" -eq 1 ]]; then
    if ! "$at_edge_script" "$edge_direction"; then
      # no longer on an edge. We've swapped to the otherside.
      pane_title="$(tmux display -p '#{q:pane_title}')";
      # TODO sleep for ssh
      pane_current_command="$(tmux display -p '#{q:pane_current_command}')";
      if pane_contains_vim ; then
        # TODO handle neovim terminal
        if [[ "$pane_title" == *"mode:i"* ]]; then
          # enter insert-normal mode for one command to allow a movement
          tmux send-keys 'C-o'
        fi
        case "$edge_direction" in
          L) vim_direction=l ;;
          D) vim_direction=k ;;
          U) vim_direction=j ;;
          R) vim_direction=h ;;
        esac
        # fudge factor of 10 splits
        tmux send-keys 10 C-w "$vim_direction"
        # TODO why does tmux show 1 after the command?
      fi
    fi
  fi
  exit 0
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
