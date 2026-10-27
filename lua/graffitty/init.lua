local M = {}
function M.setup(opts)
  opts = opts or {}
  require("graffitty.send").setup(opts.send or {})
  if opts.navigator ~= false then require("graffitty.navigator").setup(opts.navigator or {}) end
end
return M
