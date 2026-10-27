local M = {}
local directions = { left = "h", down = "j", up = "k", right = "l" }
local select_flags = { left = "-L", down = "-D", up = "-U", right = "-R" }
local config = { modes = { "n" }, tmux = "auto", command = vim.env.GRAFFITTY_BIN or "gft" }
-- Neovim owns its keys. Only a confirmed editor edge can leave the editor.
function M.step(direction)
  local key = assert(directions[direction], "Invalid navigation direction")
  local mode = vim.api.nvim_get_mode()
  local short = mode.mode:sub(1, 1)
  if mode.blocking or (short == "n" and mode.mode ~= "n" and mode.mode ~= "nt") or not vim.tbl_contains(config.modes, short) or vim.fn.pumvisible() == 1
    or vim.fn.getcmdwintype() ~= "" or vim.bo.buftype == "prompt"
    or vim.api.nvim_win_get_config(0).relative ~= "" then return "pass" end
  local before = vim.api.nvim_get_current_win()
  if short == "i" or short == "t" then vim.cmd.stopinsert() end
  local ok = pcall(vim.cmd.wincmd, key)
  if not ok then return "pass" end
  return before == vim.api.nvim_get_current_win() and "edge" or "moved"
end

local function tmux_edge(direction)
  if not vim.env.TMUX or not vim.env.TMUX_PANE then return "edge" end
  if config.tmux == false then return "pass" end
  local socket = vim.env.TMUX:match("^[^,]+")
  local function run(args)
    local cmd = { "tmux", "-S", socket }
    vim.list_extend(cmd, args)
    local ok, r = pcall(function() return vim.system(cmd, { text = true }):wait(1000) end)
    if not ok then return nil end
    return r.code == 0 and vim.trim(r.stdout or "") or nil
  end
  local edge = ({ left = "left", down = "bottom", up = "top", right = "right" })[direction]
  local state = run({ "display-message", "-p", "-t", vim.env.TMUX_PANE,
    "#{pane_at_" .. edge .. "}:#{window_zoomed_flag}:#{pane_in_mode}" })
  if not state then return "pass" end
  local at_edge, zoomed, in_mode = state:match("^(%d):(%d):(%d+)$")
  if not at_edge or in_mode ~= "0" then return "pass" end
  if at_edge == "1" or zoomed == "1" then return "edge" end
  return run({ "select-pane", "-t", vim.env.TMUX_PANE,
    select_flags[direction] }) and "moved" or "pass"
end

local function graffitty_edge(direction)
  -- tmux may have acquired its Graffitty environment after Neovim started;
  -- the short-lived CLI resolves the current client context at the boundary.
  if not vim.env.GRAFFITTY_SOCKET and not vim.env.TMUX then return "edge" end
  if vim.fn.executable(config.command) ~= 1 then return "edge" end
  local ok, result = pcall(function()
    return vim.system({ config.command, "select-pane", select_flags[direction] }, { text = true }):wait(2000)
  end)
  if not ok or result.code ~= 0 then return "pass" end
  local decoded, response = pcall(vim.json.decode, result.stdout or "")
  return decoded and type(response) == "table" and type(response.result) == "table"
    and response.result.outcome or "edge"
end
function M.move_to(direction)
  assert(directions[direction], "Invalid navigation direction: expected left, down, up, or right")
  local result = M.step(direction)
  -- Only an editor refusal permits literal delivery. A failed external call
  -- may already have moved focus, so it must never replay the original key.
  if result == "pass" then
    local literal = vim.api.nvim_replace_termcodes("<C-" .. directions[direction] .. ">", true, false, true)
    vim.api.nvim_feedkeys(literal, "n", false)
    return result
  end
  if result == "edge" then result = tmux_edge(direction) end
  if result == "edge" then result = graffitty_edge(direction) end
  return result
end
function M.move_left() return M.move_to("left") end
function M.move_down() return M.move_to("down") end
function M.move_up() return M.move_to("up") end
function M.move_right() return M.move_to("right") end

function M.setup(opts)
  config = vim.tbl_extend("force", config, opts or {})
end
return M
