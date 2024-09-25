local api = vim.api
local log = require("papis.log")
local commands = require("papis.commands")

-- Function to create a popup window for DOI input
local function create_doi_popup()
  local buf = api.nvim_create_buf(false, true)
  local width = 50
  local height = 1
  local opts = {
    relative = "editor",
    width = width,
    height = height,
    row = (vim.o.lines - height) / 2,
    col = (vim.o.columns - width) / 2,
    style = "minimal",
    border = "single",
  }

  api.nvim_open_win(buf, true, opts)
  api.nvim_buf_set_option(buf, "buftype", "prompt")
  vim.fn.prompt_setprompt(buf, "Enter DOI: ")
  vim.fn.prompt_setcallback(buf, function(input)
    api.nvim_win_close(0, true)
    if input and input ~= "" then
      vim.cmd("Papis add " .. input)
    else
      log.error("No DOI entered.")
    end
  end)
  api.nvim_command("startinsert")
end

-- Command to trigger the DOI popup
commands:add_commands({
  add = {
    impl = function(_, _)
      create_doi_popup()
    end,
  },
})

-- Keymap to trigger the DOI popup
vim.api.nvim_set_keymap("n", "<leader>pa", ":Papis add<CR>", { noremap = true, silent = true })
