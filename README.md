# 🖥️👉🖥️ graffitty.nvim

Neovim integration for Graffitty.

- Navigate between Neovim splits, tmux panes, and Graffitty panes.
- Send text or file paths to another Graffitty pane. You can also copy to the clipboard for later.

<img src="https://user-images.githubusercontent.com/12980409/205471326-27ef838a-c164-42a7-a576-2f5af3be95a8.gif" width="100%"/>

- For **interactive development**, similar to Jupyter Notebook. You can paste your code on a bash shell or an ipython interpreter.
- Uses bracketed paste when the target pane enables it, including in vim/neovim and ipython.

## Compatible Plugins

- It will detect [Nvim-Tree](https://github.com/nvim-tree/nvim-tree), [neo-tree](https://github.com/nvim-neo-tree/neo-tree.nvim), [oil.nvim](https://github.com/stevearc/oil.nvim), [Fyler](https://github.com/FylerOrg/fyler.nvim) and copy-paste the file's absolute path.  

## 🛠️ Installation

Requires Neovim 0.11+ running inside Graffitty, with `gft` available.

With lazy.nvim,

```lua
  {
    "graffitty/graffitty.nvim",
    opts = {},
    keys = {
      { "<C-h>", function() require("graffitty.navigator").move_left() end, desc = "Navigate left" },
      { "<C-j>", function() require("graffitty.navigator").move_down() end, desc = "Navigate down" },
      { "<C-k>", function() require("graffitty.navigator").move_up() end, desc = "Navigate up" },
      { "<C-l>", function() require("graffitty.navigator").move_right() end, desc = "Navigate right" },
      {
        "-",
        function()
          require("graffitty.send").send_to_pane()
          -- (Optional) exit visual mode after sending
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<esc>", true, false, true), "x", true)
        end,
        mode = { "n", "x" },
        desc = "Send to Graffitty pane",
      },
      {
        "_",
        function()
          require("graffitty.send").send_to_pane({ add_newline = false })
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<esc>", true, false, true), "x", true)
        end,
        mode = { "n", "x" },
        desc = "Send to Graffitty pane (plain)",
      },
      {
        "<space>-",
        function()
          require("graffitty.send").send_to_pane({ count_is_uid = true })
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<esc>", true, false, true), "x", true)
        end,
        mode = { "n", "x" },
        desc = "Send to Graffitty pane w/ pane uid",
      },
      {
        "<space>_",
        function()
          require("graffitty.send").send_to_pane({ count_is_uid = true, add_newline = false })
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<esc>", true, false, true), "x", true)
        end,
        mode = { "n", "x" },
        desc = "Send to Graffitty pane w/ pane uid (plain)",
      },
      {
        "<C-_>",
        function()
          require("graffitty.send").save_to_clipboard()
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<esc>", true, false, true), "x", true)
        end,
        mode = { "n", "x" },
        desc = "Save to clipboard",
      },
    },
  },
```

### Navigation

The Ctrl-H/J/K/L mappings above navigate Neovim splits first, then tmux panes,
then Graffitty panes at the outer edge. They use normal mode by default and do
not wrap. Floating dialogs, prompt buffers, and completion menus retain their keys.

Enable navigation from shells in Graffitty's `server.toml`:

```toml
[navigator]
enabled = true
```

For tmux shell navigation, install the companion `tmux-graffitty` plugin.
See [Navigator configuration](docs/navigator.md) for custom keys, additional
modes, and tmux setup.

### Sending text and paths

1. All send functions support normal (n) and visual (x) modes. Normal mode mappings will send a single line.
2. Choose pane with relative ID or unique ID (uid).
  - uid stays the same when moving panes between tabs in the same session.
  - For example, `5-` will paste selection (or current line) to the .5 pane.
  - `5<space>-` will paste selection (or current line) to the %5 pane.
  - Use `gft surfaces` to see the pane unique identifier.
3. Choose tab by giving number >= 10.
  - For example, `12-` will paste selection (or current line) to tab 1 pane 2.
  - `123-` will paste selection (or current line) to tab 12 pane 3.
4. Use `<C-_>` to copy into the clipboard. This uses Neovim's `+` register and requires a clipboard provider.
5. Omitting the number (e.g. running `-`) will use the previous pane again. The builtin filetree initially targets its connected pane; otherwise, choose a pane first.

### Recommended fyler.nvim settings

Fyler uses `-` to go to the parent directory. If using the example key bindings above, disable that mapping and use `U` instead. This frees `-` for sending paths and keeps `u` available for undoing edits.

```lua
require("fyler").setup({
  mappings = {
    n = {
      ["-"] = { disabled = true },
      ["U"] = { action = "visit", args = { parent = true } },
    },
  },
  -- ...
})
```

### Recommended Nvim-Tree settings

If using the example key bindings above, it is recommended to change Nvim-Tree's keybinding (remove '-' and use 'u' instead):

```lua
local function nvim_tree_on_attach(bufnr)
  local api = require "nvim-tree.api"
  api.config.mappings.default_on_attach(bufnr)

  local function opts(desc)
    return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
  end

  vim.keymap.set("n", "u", api.tree.change_root_to_parent, opts "Up")
  vim.keymap.set("n", "-", "", { buffer = bufnr })
  vim.keymap.del("n", "-", { buffer = bufnr })
end

require("nvim-tree").setup({
  on_attach = nvim_tree_on_attach,
  -- ...
})
```

### Recommended oil.nvim settings

If using the example key bindings above, it is recommended to change oil.nvim's keybinding (remove '-' and use 'U' instead):

```lua
require("oil").setup({
  keymaps = {
    ["g?"] = { "actions.show_help", mode = "n" },
    ["<CR>"] = "actions.select",
    ["<C-s>"] = { "actions.select", opts = { vertical = true } },
    ["<C-h>"] = { "actions.select", opts = { horizontal = true } },
    ["<C-t>"] = { "actions.select", opts = { tab = true } },
    ["<C-p>"] = "actions.preview",
    ["<C-c>"] = { "actions.close", mode = "n" },
    ["<C-l>"] = "actions.refresh",
    -- ["-"] = { "actions.parent", mode = "n" },
    -- ["_"] = { "actions.open_cwd", mode = "n" },
    ["U"] = { "actions.parent", mode = "n" },
    ["`"] = { "actions.cd", mode = "n" },
    ["g~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
    ["gs"] = { "actions.change_sort", mode = "n" },
    ["gx"] = "actions.open_external",
    ["g."] = { "actions.toggle_hidden", mode = "n" },
    ["g\\"] = { "actions.toggle_trash", mode = "n" },
  },
  use_default_keymaps = false,
})
```
