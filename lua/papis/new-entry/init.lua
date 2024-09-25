local api = vim.api
local log = require("papis.log")
local commands = require("papis.commands")

local function open_floating_terminal(cmd)
  -- Define the size and position of the floating window
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  -- Create a buffer for the floating window
  local buf = vim.api.nvim_create_buf(false, true)

  -- Define the window options
  local opts = {
    style = "minimal",
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
  }

  -- Create the floating window
  local win = vim.api.nvim_open_win(buf, true, opts)

  -- Open a terminal in the floating window and run the command
  vim.fn.termopen(cmd)

  -- Set some options for the terminal buffer
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "filetype", "terminal")
end

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
      local papis_cmd = "papis add " .. input
      open_floating_terminal(papis_cmd)
      log.info("Output: " .. papis_cmd)
    else
      log.error("No DOI entered.")
      -- create an neovim message that says no doi is entered
      vim.notify("No DOI entered.", vim.log.levels.ERROR)
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
vim.api.nvim_set_keymap("n", "<leader>paa", ":Papis add auto<CR>", { noremap = true, silent = true })
