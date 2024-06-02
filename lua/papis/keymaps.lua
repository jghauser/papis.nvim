--
-- PAPIS | KEYMAPS
--
--
-- Sets up default keymaps.
--

local config = require("papis.config")

local M = {}

local keymaps = {
  ["search"] = {
    open_search_normal = {
      mode = "n",
      lhs = "<leader>pp",
      rhs = function()
        require("telescope").extensions.papis.papis()
      end,
      opts = { desc = "Papis: search library" },
    },
    open_search_insert = {
      mode = "i",
      lhs = "<c-o>p",
      rhs = function()
        require("telescope").extensions.papis.papis()
      end,
      opts = { desc = "Papis: search library" },
    },
  },

  ["cursor-actions"] = {
    open_file = {
      mode = "n",
      lhs = "<leader>pof",
      rhs = function()
        return require("papis.cursor-actions").open_file()
      end,
      opts = { desc = "Papis: open file under cursor" },
    },
    edit_entry = {
      mode = "n",
      lhs = "<leader>pe",
      rhs = function()
        return require("papis.cursor-actions").edit_entry()
      end,
      opts = { desc = "Papis: edit entry under cursor" },
    },
    open_note = {
      mode = "n",
      lhs = "<leader>pon",
      rhs = function()
        return require("papis.cursor-actions").open_note()
      end,
      opts = { desc = "Papis: open note under cursor" },
    },
    show_popup = {
      mode = "n",
      lhs = "<leader>pi",
      rhs = function()
        return require("papis.cursor-actions").show_popup()
      end,
      opts = { desc = "Papis: show entry info popup" },
    },
  },
}

---Sets up the keymaps for all enabled modules
function M.setup()
  for module_name, module_keymaps in pairs(keymaps) do
    if config["enable_modules"][module_name] then
      for _, keymap in pairs(module_keymaps) do
        local opts = vim.deepcopy(keymap["opts"])
        opts["silent"] = true
        opts["buffer"] = true
        vim.keymap.set(keymap["mode"], keymap["lhs"], keymap["rhs"], opts)
      end
    end
  end
end

return M
