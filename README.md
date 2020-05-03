# tmux-navigate

Intelligently navigate tmux panes and Vim splits using the same keys.
This also supports SSH tunnels where Vim is running on a remote host.

  | inside Vim? | is Zoomed? | Action taken by key binding |
  | ----------- | ---------- | --------------------------- |
  | No          | No         | Focus directional tmux pane |
  | No          | Yes        | Nothing: ignore key binding |
  | Yes         | No         | Seamlessly focus Vim / tmux |
  | Yes         | Yes        | Focus directional Vim split |

See https://sunaku.github.io/tmux-select-pane.html for documentation.

## Installation

1. Install the [TPM] framework for tmux.

[TPM]: https://github.com/tmux-plugins/tpm

2. Add this line to your `~/.tmux.conf`:
```sh
set -g @plugin 'sunaku/tmux-navigate'
```

3. Configure your navigation shortcuts:
```sh
set -g @navigate-no-bindings
bind-key -n M-h  run-shell -b "#{navigate_pane} left"
bind-key -n M-j  run-shell -b "#{navigate_pane} down"
bind-key -n M-k  run-shell -b "#{navigate_pane} up"
bind-key -n M-l  run-shell -b "#{navigate_pane} right"
bind-key -n M-\\ run-shell -b "#{navigate_pane} back"
```

4. Timeout for very slow Vim (optional):
```sh
# set this ONLY IF your Vim is very slow
set -g @navigate-timeout 1.618 # seconds
# propagation delay for Vim title change
```

5. Reload your tmux configuration file.

6. Type <kbd>prefix</kbd>+<kbd>I</kbd>.

### Vim integration - when using Vim remotely via SSH

When you run `ssh` in a tmux pane to connect to another machine and run Vim
there, tmux only sees `ssh` running in the pane: it doesn't know about Vim!

To help tmux see Vim, let's make Vim announce itself through the pane title by
loading the provided `plugin/tmux-navigate.vim` script into your Vim session.

You can do this either (1) manually by running the `:source` command in Vim,
or (2) have Vim do it automatically on startup by installing this repository
using your favorite Vim plugin manager or by symlinking from this repository:

> Option 1: use your favorite Vim plugin manager
```vim
Plug 'sunaku/tmux-navigate'
```

> Option 2: symlink from your tmux plugins clone
```sh
ln -s ~/.tmux/plugins/tmux-navigate/plugin/tmux-navigate.vim ~/.vim/plugin/
```

## License

[Spare A Life]: https://sunaku.github.io/vegan-for-life.html
> Like my work? 👍 Please [spare a life] today as thanks! 🐄🐖🐑🐔🐣🐟✨🙊✌  
> Why? For 💕 ethics, the 🌎 environment, and 💪 health; see link above. 🙇

(the ISC license)

Copyright 2018 Suraj N. Kurapati <https://github.com/sunaku>

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
