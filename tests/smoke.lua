-- Run from this plugin directory: nvim --clean --headless -l tests/smoke.lua
vim.opt.rtp:prepend(vim.fn.getcwd())
local grab = require("graffitty.send.content_grabber").smart_grab
local function eq(actual, expected)
  assert(vim.deep_equal(actual, expected), vim.inspect({ actual = actual, expected = expected }))
end
local function normal(keys) vim.cmd.normal({ keys, bang = true }) end
local function escape() normal(vim.api.nvim_replace_termcodes("<Esc>", true, false, true)) end

vim.api.nvim_buf_set_lines(0, 0, -1, false, { "aΩ界z", "xy", "" })
normal("gg0")
eq(grab(), { "aΩ界z" })
normal("lvll")
eq(grab(), { "Ω界z" })
escape()
normal("gg0Vj")
eq(grab(), { "aΩ界z", "xy" })
escape()
normal("gg0l" .. string.char(22) .. "jjll")
eq(grab(), { "aΩ", "xy", "" })
escape()

normal("gg0")
local send = require("graffitty.send")
local calls = {}
send.rpc = function(method, params)
  table.insert(calls, { method, params })
  return { pane = "%99" }
end
vim.keymap.set("n", "-", function() send.send_to_pane() end)
vim.keymap.set("n", "_", function() send.send_to_pane({ count_is_uid = true, add_newline = false }) end)
vim.cmd.normal("12-")
eq(calls[#calls][2].target, ":1.2")
vim.cmd.normal("5_")
eq(calls[#calls][2].target, "%5")
eq(calls[#calls][2].enter, false)
vim.cmd.normal("-")
send.send_to_pane({ content = { "one", "two" } })
eq(calls[#calls], { "pane.send", { target = "%99", text = "one\ntwo", enter = true } })
send.send_to_pane({ pane_identifier = ".2", content = "literal ' $()" })
eq(calls[#calls][2].target, ".2")
print("GRAFFITTY_SEND_PASS")
