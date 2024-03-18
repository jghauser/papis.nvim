local o = vim.o
local cmd = vim.cmd
local fn = vim.fn

o.termguicolors = true
o.swapfile = false
cmd.colorscheme("industry")

-- install required plugins
cmd.packadd("plenary.nvim")
cmd.packadd("nvim-treesitter")
cmd.packadd("sqlite.lua")
cmd.packadd("nui.nvim")
cmd.packadd("nvim-cmp")
vim.opt.runtimepath:prepend(vim.fn.getcwd())

-- setup dependencies
local cmp = require("cmp")
cmp.setup({
  mapping = cmp.mapping.preset.insert({
    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-e>"] = cmp.mapping.abort(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
  }),
  sources = cmp.config.sources({
    -- your other source
    { name = "papis" },
  }),
})
-- require("nvim-treesitter.configs").setup({})
-- require("treesitter-context").setup({})

-- remap leader
vim.g.mapleader = " "

math.randomseed(os.time())
local rand_num = string.sub(tostring(math.random()), 3)
local db_path = vim.fn.stdpath("cache") .. "/papis_db/papis-nvim-test-" .. rand_num .. ".sqlite3"

---Sets up papis
---@param opts table? Custom configuration options
---@param no_autostart boolean? Disable autostart
function _Load_papis(opts, no_autostart)
  local unloadPapis = vim.api.nvim_create_augroup("unloadPapis", { clear = true })
  vim.api.nvim_create_autocmd({ "ExitPre" }, {
    pattern = "*",
    callback = function()
      _Unload_papis()
    end,
    group = unloadPapis,
    desc = "Unload papis",
  })
  local default_config = {
    papis_python = {
      dir = fn.getcwd() .. "/tests/files/library",
      info_name = "info.yaml",
      notes_name =
      [[{{(doc["author_list"][0].get('surname','') or doc["author_list"][0].get('family','') ) if doc["author_list"] else doc["author"].split()[0] or doc["editor"].split()[0]}}_{{doc["year"]}}_{{'-'.join(doc["title"].split()[0:4])}}.norg]],
      opentool = "okular",
    },
    enable_modules = {
      ["debug"] = true,
    },
    enable_keymaps = true,
    db_path = db_path,
    log = {
      level = "trace",
    },
  }
  local new_config = vim.tbl_deep_extend("force", default_config, opts or {})
  local init_result = require("papis").setup(new_config)

  -- start papis.nvim
  if not no_autostart then
    cmd.PapisStart()
  end

  -- autocmd to clean things up after closing
  local unloadPapis = vim.api.nvim_create_augroup('unloadPapis', { clear = true })
  vim.api.nvim_create_autocmd('ExitPre', {
    group = unloadPapis,
    callback = _Unload_papis
  })

  return init_result
end

function _Unload_papis()
  for name, _ in pairs(package.loaded) do
    if name:match("^papis") then
      package.loaded[name] = nil
    end
  end
  os.remove(db_path)
end
