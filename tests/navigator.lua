vim.opt.rtp:prepend(vim.fn.getcwd())
vim.env.GRAFFITTY_SOCKET = nil
vim.env.TMUX, vim.env.TMUX_PANE = nil, nil
local nav = require("graffitty.navigator")
vim.o.splitright, vim.o.splitbelow = true, true
local function press(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "xt", false)
end

-- Setup must leave both Neovim defaults and user mappings untouched while
-- the explicit movement API remains usable from custom keymaps.
vim.keymap.set("n", "<C-h>", function() end, { desc = "User mapping" })
local previous = {}
for _, key in ipairs({ "h", "j", "k", "l" }) do
  previous[key] = vim.fn.maparg("<C-" .. key .. ">", "n", false, true)
end
require("graffitty").setup({})
for key, mapping in pairs(previous) do
  assert(vim.deep_equal(mapping, vim.fn.maparg("<C-" .. key .. ">", "n", false, true)),
    "Setup must preserve " .. key)
end
for _, spec in ipairs({
  { "vsplit", "left", "right", nav.move_left, nav.move_right },
  { "split", "up", "down", nav.move_up, nav.move_down },
}) do
  vim.cmd.only()
  local first = vim.api.nvim_get_current_win()
  vim.cmd(spec[1])
  local second = vim.api.nvim_get_current_win()
  assert(spec[4]() == "moved" and vim.api.nvim_get_current_win() == first)
  assert(spec[5]() == "moved" and vim.api.nvim_get_current_win() == second)
  assert(nav.move_to(spec[2]) == "moved" and vim.api.nvim_get_current_win() == first)
  assert(nav.move_to(spec[3]) == "moved" and vim.api.nvim_get_current_win() == second)
  assert(nav.move_to(spec[3]) == "edge" and vim.api.nvim_get_current_win() == second)
  vim.keymap.set("n", "<F6>", spec[4])
  vim.keymap.set("n", "<F7>", spec[5])
  press("<F6>"); assert(vim.api.nvim_get_current_win() == first)
  press("<F7>"); assert(vim.api.nvim_get_current_win() == second)
end
vim.keymap.del("n", "<F6>")
vim.keymap.del("n", "<F7>")
assert(not pcall(nav.move_to, "invalid"), "Invalid directions must fail before moving")
vim.keymap.del("n", "<C-h>")
-- The same callbacks used by lazy.nvim's keys table own navigation and fallback.
for key, move in pairs({ h = nav.move_left, j = nav.move_down, k = nav.move_up, l = nav.move_right }) do
  vim.keymap.set("n", "<C-" .. key .. ">", move)
end
for _, spec in ipairs({ { "vsplit", "l", "h" }, { "split", "j", "k" } }) do
  vim.cmd.only()
  local first = vim.api.nvim_get_current_win()
  vim.cmd(spec[1])
  local second = vim.api.nvim_get_current_win()
  press("<C-" .. spec[3] .. ">"); assert(vim.api.nvim_get_current_win() == first)
  press("<C-" .. spec[2] .. ">"); assert(vim.api.nvim_get_current_win() == second)
end
vim.cmd.only()
vim.bo.filetype = "fyler"
for _, direction in ipairs({ "left", "down", "up", "right" }) do assert(nav.step(direction) == "edge") end
local overridden = false
vim.keymap.set("n", "<C-l>", function() overridden = true end, {buffer=true})
press("<C-l>")
assert(overridden, "Neovim's buffer-local mapping takes precedence")
vim.keymap.del("n", "<C-l>", {buffer=true})
local win = vim.api.nvim_open_win(vim.api.nvim_create_buf(false,true),true,{relative="editor",row=1,col=1,width=10,height=3})
assert(nav.step("left") == "pass", "Floating dialog retains keys")
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "abc" })
vim.api.nvim_win_set_cursor(0, { 1, 2 })
press("<C-h>")
assert(vim.api.nvim_win_get_cursor(0)[2] == 1, "Floating buffer receives literal Ctrl-H")
vim.api.nvim_win_close(win,true)
assert(package.loaded["graffitty.bridge"] == nil, "Navigation needs no persistent bridge")

-- Only an outer edge starts gft, with no retry after an uncertain result.
local system, executable = vim.system, vim.fn.executable
local calls = {}
vim.env.GRAFFITTY_SOCKET = "/test/navigation.sock"
vim.fn.executable = function() return 1 end
vim.system = function(argv)
  calls[#calls + 1] = argv
  return { wait = function() return { code = 0, stdout = '{"result":{"outcome":"moved"}}' } end }
end
vim.cmd.vsplit()
assert(nav.move_left() == "moved" and #calls == 0, "Internal split movement must not spawn gft")
assert(nav.move_left() == "moved" and #calls == 1)
assert(calls[1][2] == "select-pane" and calls[1][3] == "-L")
vim.system = function(argv)
  calls[#calls + 1] = argv
  return { wait = function() return { code = 124, stdout = "" } end }
end
local outcome, passthrough = nav.move_left()
assert(outcome == "pass" and not passthrough and #calls == 2, "Timed-out CLI must not retry or replay a key")
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "abc" })
vim.api.nvim_win_set_cursor(0, { 1, 2 })
press("<C-h>")
assert(#calls == 3 and vim.api.nvim_win_get_cursor(0)[2] == 2,
  "Mapped navigation must not replay Ctrl-H after a timed-out CLI")
vim.system, vim.fn.executable = system, executable
vim.env.GRAFFITTY_SOCKET = nil
print("GRAFFITTY_NAVIGATOR_PASS")
