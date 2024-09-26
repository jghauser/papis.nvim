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

-- Function to create floating window
local function create_form_window()
  local buf = vim.api.nvim_create_buf(false, true) -- Create a buffer
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = 40,
    height = 10,
    col = math.floor((vim.o.columns - 40) / 2),
    row = math.floor((vim.o.lines - 10) / 2),
    style = "minimal",
  })
  return buf, win
end

-- Function to populate the form in the buffer
local function populate_form(buf)
  local form = {
    "Title: ",
    "Authors: ",
    "Year: ",
    "Tags: ",
  }
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, form)
  vim.api.nvim_buf_set_option(buf, "modifiable", true)
end

-- Function to extract form data
local function get_form_data(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local form_data = {
    title = lines[1]:sub(8), -- Strip "Title: "
    authors = lines[2]:sub(10), -- Strip "Authors: "
    year = lines[3]:sub(7), -- Strip "Year: "
    tags = lines[4]:sub(7), -- Strip "Tags: "
  }
  return form_data
end

-- Function to construct the papis command and execute it
local function submit_form(data)
  -- Construct the papis command with the user input
  local papis_command = string.format(
    "papis add --title '%s' --authors '%s' --year '%s' --tags '%s'",
    data.title,
    data.authors,
    data.year,
    data.tags
  )

  -- Execute the papis command
  vim.fn.system(papis_command)

  -- Print the command to confirm it's correct (for debugging)
  print("Executed Command: ", papis_command)
end

-- Function to open the form and handle submission
local function open_form()
  local buf, win = create_form_window()
  populate_form(buf)

  -- Bind <Enter> to submit the form
  vim.api.nvim_buf_set_keymap(buf, "n", "<CR>", "", {
    callback = function()
      local data = get_form_data(buf)
      submit_form(data)
      vim.api.nvim_win_close(win, true)
    end,
    noremap = true,
    silent = true,
  })
end

-- Create command to open the form
vim.api.nvim_create_user_command("OpenForm", open_form, {})

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

-- Function to handle manual entry via form
local function manual_entry()
  local buf, win = create_form_window() -- Create the floating window for the form
  populate_form(buf) -- Populate form with fields: Title, Authors, Year, Tags

  -- Bind <Enter> to submit the form
  vim.api.nvim_buf_set_keymap(buf, "n", "<CR>", "", {
    callback = function()
      local data = get_form_data(buf) -- Extract form data (Title, Authors, Year, Tags)
      submit_form(data) -- Construct and execute the papis command
      vim.api.nvim_win_close(win, true) -- Close the floating window after submission
    end,
    noremap = true,
    silent = true,
  })
end

-- Command to handle Papis subcommands
vim.api.nvim_create_user_command("Papis", function(opts)
  local subcommand = opts.args
  if subcommand == "add auto" then
    create_doi_popup() -- Assuming you have this function elsewhere
  elseif subcommand == "add manual" then
    manual_entry() -- Calls the manual entry form
  else
    print("Unknown subcommand: " .. subcommand)
  end
end, { nargs = 1 })

-- Keymap to trigger the DOI popup and manual entry
vim.api.nvim_set_keymap("n", "<leader>paa", ":Papis add auto<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>pam", ":Papis add manual<CR>", { noremap = true, silent = true })
