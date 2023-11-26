--
-- PAPIS | KEYMAPS
--
--
-- Sets up default keymaps.
--

local config = require("papis.config")

local M = {}

local keybinds = {
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
      lhs = "<c-p>p",
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
  for module_name, module_keybinds in pairs(keybinds) do
    if config["enable_modules"][module_name] then
      vim.api.nvim_create_autocmd({ "BufEnter" }, {
        pattern = config["init_filenames"],
        callback = function()
          for _, keybind in pairs(module_keybinds) do
            local opts = vim.deepcopy(keybind["opts"])
            opts["silent"] = true
            opts["buffer"] = true
            vim.keymap.set(keybind["mode"], keybind["lhs"], keybind["rhs"], opts)
          end
        end,
        group = vim.api.nvim_create_augroup("setPapisKeymaps_" .. module_name, { clear = true }),
        desc = "Set Papis keymaps",
      })
    end
  end
end

return M
