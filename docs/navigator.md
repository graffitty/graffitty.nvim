# Navigator

Navigation is implemented in `graffitty.navigator`. The shared entry point
configures both sending and navigation, but never installs keybindings:

```lua
require("graffitty").setup({
  send = {},
  navigator = { modes = { "n" }, tmux = "auto" },
})
```

Use the lazy.nvim `keys` table in the [README](../README.md) to load the plugin
on the first navigation or send keypress.

Set `navigator = false` to configure only send. Use
`require("graffitty.navigator").setup(...)` to configure navigation alone.
For custom mappings without lazy.nvim:

```lua
local navigator = require("graffitty.navigator")
vim.keymap.set("n", "<M-h>", navigator.move_left)
vim.keymap.set("n", "<M-j>", navigator.move_down)
vim.keymap.set("n", "<M-k>", navigator.move_up)
vim.keymap.set("n", "<M-l>", navigator.move_right)
```

`navigator.move_to(direction)` accepts `"left"`, `"down"`, `"up"`, and
`"right"`. These functions try a Neovim split, then a native tmux pane move,
then invoke `gft select-pane -L|-D|-U|-R` at the outer edge.
`gft` must be on PATH, or set `command` in navigator options. Set `tmux = false`
to stop at Neovim's boundary when running inside tmux.

Enable shell navigation in Graffitty's `server.toml`:

```toml
[navigator]
enabled = true
```

Graffitty passes the original keys to foreground applications; Neovim owns its
mappings and modes. Custom mappings in Neovim do not change Graffitty's
`navigator.bindings` or tmux's bindings.

Normal mode is enabled by default. Insert and terminal mode are opt-in via
`modes = { "n", "i", "t" }` in navigator options and
`mode = { "n", "i", "t" }` on each key mapping; navigation leaves those modes. Command-line input,
completion menus, prompt buffers and floating dialogs retain their keys.

Without Graffitty, the Ctrl mappings navigate Neovim splits and then tmux panes
if tmux is present. Outside edges do not wrap.

For tmux shell navigation, install [tmux-graffitty](https://github.com/graffitty/tmux-graffitty)
through TPM. Add before TPM initialization:

```tmux
set -g @plugin 'graffitty/tmux-graffitty'
run '~/.tmux/plugins/tpm/tpm'
```

Reload with `tmux source-file ~/.tmux.conf`, then press **prefix + I** to install.

The plugin passes keys to foreground applications, uses `select-pane` for
internal moves, and runs `gft select-pane` only at an outer edge. It updates the
Graffitty environment on attach and supplies the initiating client TTY, so an
existing tmux session can be attached in another Graffitty pane. One tmux layer
is supported. Copy mode keeps its keys; zoomed panes do not unzoom. Ordinary
SSH passes Ctrl keys through and does not hand navigation back to local Graffitty.

Tests: `nvim --clean --headless -l tests/navigator.lua` and
`nvim --clean --headless -l tests/smoke.lua`, from this plugin directory.
