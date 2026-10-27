-- Selection semantics adapted from tmux-send.nvim. Use Neovim's region
-- reader for multibyte text, exclusive selection and ragged visual blocks.
local M = {}
local function get_visual_selection()
  local mode = vim.fn.mode():sub(1, 1)
  mode = ({ s = "v", S = "V", [string.char(19)] = string.char(22) })[mode] or mode
  return vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), {
    type = mode, exclusive = vim.o.selection == "exclusive",
  })
end

---Grab content based on the filetype, vim mode, etc.
---For example, if the filetype is NvimTree, then grab the full path of the file
---In select/visual mode, grab the selected text.
---In other modes, grab the line under the cursor.
---@return string[]
M.smart_grab = function()
  -- NvimTree is open. Get the file path instead of copying the content.
  if vim.bo.filetype == "fyler_finder" then
    local finder = require("fyler.finder")
    local instance = finder.instance_get_or_nil()
    local entry = instance and finder.parse_cursor_line(instance)
    return entry and { " " .. vim.fn.shellescape(entry.path) } or {}
  elseif vim.bo.filetype == "NvimTree" then
    local nt_api = require("nvim-tree.api")
    local path = nt_api.tree.get_node_under_cursor().absolute_path
    if path == nil then
      local nt_nodes = nt_api.tree.get_nodes()
      path = nt_nodes.absolute_path -- root dir path
    end
    return { " " .. vim.fn.shellescape(path) }
  elseif vim.bo.filetype == "neo-tree" then
    local node = require("neo-tree.sources.manager").get_state("filesystem").tree:get_node()
    if node.path ~= nil then
      return { " " .. vim.fn.shellescape(node.path) }
    end

    -- if you are on a message like (2 hidden items), then return empty
    return {}
  elseif vim.bo.filetype == "oil" then
    local oil = require("oil")
    local entry = oil.get_cursor_entry()
    if entry == nil then
      return {}
    end

    local path = oil.get_current_dir() .. entry.name
    return { " " .. vim.fn.shellescape(path) }
  end

  local mode = vim.api.nvim_get_mode().mode
  -- \22 is the ASCII code for CTRL-V (^V)
  if vim.list_contains({ "v", "V", "vs", "Vs", "s", "S", "CTRL-V", "\22", "CTRL-S", string.char(19) }, mode) then
    return get_visual_selection()
  else
    return { vim.fn.getline(".") }
  end
end

return M
