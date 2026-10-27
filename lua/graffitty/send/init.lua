-- Adapted from kiyoon/tmux-send.nvim (MIT; see LICENSE).
local M = {}
local config = { command = vim.env.GRAFFITTY_BIN or "gft", target = nil }
local previous

function M.setup(opts)
  config = vim.tbl_extend("force", config, opts or {})
end

function M.rpc(method, params)
  local output = vim.fn.system({ config.command, "rpc", method, "--params", vim.json.encode(params or {}) })
  local ok, response = pcall(vim.json.decode, output)
  if vim.v.shell_error ~= 0 or not ok or type(response) ~= "table" or response.error then
    local message = ok and type(response) == "table" and response.error and response.error.message or output
    vim.notify(tostring(message), vim.log.levels.ERROR, { title = "graffitty.nvim" })
    return nil
  end
  return response.result or response
end

---Same count convention as tmux-send: 5 = pane 5, 12 = tab 1 pane 2.
---Stable IDs use count_is_uid or pane_identifier = "%12".
function M.send_to_pane(opts)
  opts = opts or {}
  local target = opts.pane_identifier
  if not target then
    local count = vim.v.count
    if count > 0 then
      if opts.count_is_uid then target = "%" .. count
      elseif count < 10 then target = "." .. count
      else target = ":" .. math.floor(count / 10) .. "." .. (count % 10) end
    else
      target = previous or config.target or "connected"
    end
  end
  local content = opts.content
  if content == nil then content = require("graffitty.send.content_grabber").smart_grab() end
  if type(content) == "table" then content = table.concat(content, "\n") end
  if type(content) ~= "string" or content == "" then return end
  local result = M.rpc("pane.send", { target = target, text = content, enter = opts.add_newline ~= false })
  if result then previous = result.pane or target end
  return result
end

function M.save_to_clipboard()
  local content = require("graffitty.send.content_grabber").smart_grab()
  vim.fn.setreg("+", content)
  return content
end

return M
