--
-- PAPIS | KEYMAPS
--
--
-- Sets up default keymaps.
--

local api = vim.api
local config = require("papis.config")

local M = {}

---@class PapisKeymaps
---@type table<string, table>
local keymaps_tbl = {}

--- Sets papis.nvim keymaps
local function create_keymaps()
  for _, module_keymaps in pairs(keymaps_tbl) do
    for _, keymap in pairs(module_keymaps) do
      local opts = vim.deepcopy(keymap.opts)
      opts.silent = true
      opts.buffer = true
      vim.keymap.set(keymap.mode, keymap.lhs, keymap.rhs, opts)
    end
  end
end

---Creates the `autocmd` that sets keymaps for configured buffers
local function make_keymap_autocmd()
  local create_papis_keymap = api.nvim_create_augroup("createPapisKeymap", { clear = true })
  api.nvim_create_autocmd("FileType", {
    pattern = config.init_filetypes,
    callback = create_keymaps,
    group = create_papis_keymap,
    desc = "Set Papis keymap",
  })
end

---Sets up the keymaps and autocmds for keymaps
function M:setup()
  -- create keymaps for the buffer when papis is first started
  create_keymaps()
  -- creates keymaps for all subsequent buffers
  make_keymap_autocmd()
end

---Recursively merges a module's keymap table with the general keymaps table
---@param module_keymaps table A table with a module's keymaps
function M:add_keymaps(module_keymaps)
  if config.enable_keymaps then
    table.insert(keymaps_tbl, module_keymaps)
  end
end

return M
