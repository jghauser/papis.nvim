--
-- PAPIS | COMPLETION
--
--
-- Initialises the papis.nvim completion module.
--

local log = require("papis.log")

local has_cmp, cmp = pcall(require, "cmp")
if not has_cmp then
  vim.notify("The plugin nvim-cmp wasn't found but the respective papis.nvim module is configured to be loaded.",
    vim.log.levels.ERROR)
  return nil
end

local M = {}

---Sets up the papis.nvim cmp completion source
function M.setup()
  log.debug("Cmp: setting up module")
  require("papis.completion.data").init()
  cmp.register_source("papis", require("papis.completion.source").new())
end

return M
