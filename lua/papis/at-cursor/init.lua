--
-- PAPIS | AT-CURSOR
--
--
-- Various functionalities when the cursor is over a citation reference.
--

local NuiPopup = require("nui.popup")
local nuiAutocmd = require("nui.utils.autocmd")
local nuiEvent = require("nui.utils.autocmd").event

local log = require("papis.log")
local config = require("papis.config")
local popup_format = config["at-cursor"].popup_format
local auto_popup = config["at-cursor"].auto_popup
local utils = require("papis.utils")
local commands = require("papis.commands")
local keymaps = require("papis.keymaps")
local db = assert(require("papis.sqlite-wrapper"), "Failed to load papis.sqlite-wrapper")

---Tries to identify the ref under cursor
---@return string|nil ref Nil if nothing is found, otherwise is the identified ref
local function get_ref_under_cursor()
  local cite_format = config:get_cite_format()
  local start_str = cite_format.start_str
  local start_pattern = cite_format.start_pattern
  local ref_prefix = cite_format.ref_prefix

  -- get current line and cursor position
  local current_line = vim.api.nvim_get_current_line()
  local _, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))
  cursor_col = cursor_col + 1 -- Lua is 1-indexed

  -- Find the start and end of the word under the cursor
  local line_until_cursor = current_line:sub(1, cursor_col)
  local word_start_col = line_until_cursor:find("[^%s,;]*$") or 1
  local line_after_cursor = current_line:sub(cursor_col)
  local word_end_col = cursor_col + (line_after_cursor:find("[%s,;%]]") or #line_after_cursor) - 1

  -- Extract the word
  local ref = current_line:sub(word_start_col, word_end_col)

  -- First check if a start pattern is defined and try to use it
  if start_pattern then
    local _, pattern_end = ref:find(start_pattern)
    if pattern_end then
      ref = ref:sub(pattern_end + 1)
    end
  elseif start_str then
    -- If no pattern, use start_str
    local escaped_start_str = start_str:gsub("%W", "%%%0")
    local _, ref_start = string.find(ref, escaped_start_str)
    if ref_start then
      ref = string.sub(ref, ref_start + 1)
    end
  end

  -- if we found the ref_prefix in the string, we need to strip it
  if ref_prefix then
    local escaped_ref_prefix = ref_prefix:gsub("%W", "%%%0")
    local _, ref_start = string.find(ref, escaped_ref_prefix)
    if ref_start then
      ref_start = ref_start + 1
      ref = string.sub(ref, ref_start)
    end
  end

  -- remove all punctuation characters and white space at the beginning and end of string
  ref = ref:gsub("^[%p%s]*(.-)[%p%s]*$", "%1")

  return ref
end

---Runs function if there is a valid ref under cursor which exists in the database
---@param fun function The function to be run with the papis_id
---@param self? table Self argument to be passed to fun
---@param type? "note"|"info" Type argument to be passed to fun
---@param dont_notify? boolean If true, don't notify the user if no valid ref is found
local function if_ref_valid_run_fun(fun, self, type, dont_notify)
  local ref = get_ref_under_cursor()
  local entry = db.data:get({ ref = ref }, { "papis_id" })
  if not vim.tbl_isempty(entry) then
    local papis_id = entry[1].papis_id
    if self then
      fun(self, papis_id, type)
    else
      fun(papis_id, type)
    end
  elseif dont_notify ~= true then
    vim.notify(string.format("No entry in database corresponds to '%s'", ref), vim.log.levels.WARN)
  end
end

---Creates a popup with information regarding the entry specified by `ref`
---@param papis_id string The `papis_id` of the entry
local function create_hover_popup(papis_id)
  local entry = db.data:get({ papis_id = papis_id })[1]
  local popup_lines, width = utils:make_nui_lines(popup_format, entry)

  local popup = NuiPopup({
    position = 1,
    size = {
      width = width,
      height = #popup_lines,
    },
    relative = "cursor",
    border = {
      style = "single",
    },
  })

  local bufnr = vim.api.nvim_get_current_buf()
  nuiAutocmd.buf.define(bufnr, { nuiEvent.BufLeave, nuiEvent.CursorMoved, nuiEvent.BufWinLeave, nuiEvent.InsertEnter },
    function()
      popup:unmount()
    end, { once = true })

  -- mount/open the component
  popup:mount()

  for line_nr, line in ipairs(popup_lines) do
    line:render(popup.bufnr, -1, line_nr)
  end
end

-- Auto-popup state management
local auto_popup_timer = nil

---Sets up auto-popup timer
local function setup_auto_popup_timer()
  if auto_popup_timer then
    auto_popup_timer:stop()
    auto_popup_timer:close()
  end

  auto_popup_timer = vim.uv.new_timer()
  assert(auto_popup_timer, "Failed to create libuv timer")
  auto_popup_timer:start(auto_popup.delay, 0, vim.schedule_wrap(function()
    if_ref_valid_run_fun(create_hover_popup, nil, nil, true)
    auto_popup_timer = nil
  end))
end

---Sets up auto-popup autocmds
local function setup_auto_popup()
  -- Set up autocmd for auto-popup
  local group = vim.api.nvim_create_augroup("PapisAtCursorAutoPopup", { clear = true })

  vim.api.nvim_create_autocmd("CursorMoved", {
    group = group,
    callback = setup_auto_popup_timer,
    desc = "Handle cursor movement for Papis auto-popup",
  })
end

---@type PapisSubcommandTable
local module_subcommands = {
  ["at-cursor"] = {
    impl = function(args, _)
      if args[1] == "open-file" then
        if_ref_valid_run_fun(utils.do_open_attached_files, utils)
      elseif args[1] == "open-note" then
        if_ref_valid_run_fun(utils.do_open_text_file, utils, "note")
      elseif args[1] == "edit" then
        if_ref_valid_run_fun(utils.do_open_text_file, utils, "info")
      elseif args[1] == "show-popup" then
        if_ref_valid_run_fun(create_hover_popup)
      end
    end,
    complete = function(subcmd_arg_lead)
      local at_cursor_args = {
        "open-file",
        "open-note",
        "edit",
        "show-popup",
      }
      return vim.iter(at_cursor_args)
          :filter(function(install_arg)
            return install_arg:find(subcmd_arg_lead) ~= nil
          end)
          :totable()
    end,
  }
}

---@type PapisKeymapTable
local module_keymaps = {
  open_file = {
    mode = "n",
    lhs = "<leader>pf",
    rhs = function()
      vim.cmd("Papis at-cursor open-file")
    end,
    opts = { desc = "Papis: open file under cursor" },
  },
  edit_entry = {
    mode = "n",
    lhs = "<leader>pe",
    rhs = function()
      vim.cmd("Papis at-cursor edit")
    end,
    opts = { desc = "Papis: edit entry under cursor" },
  },
  open_note = {
    mode = "n",
    lhs = "<leader>pn",
    rhs = function()
      vim.cmd("Papis at-cursor open-note")
    end,
    opts = { desc = "Papis: open note under cursor" },
  },
  show_popup = {
    mode = "n",
    lhs = "<leader>pi",
    rhs = function()
      vim.cmd("Papis at-cursor show-popup")
    end,
    opts = { desc = "Papis: show entry info popup" },
  },
}

---@class PapisAtCursor
local M = {}

---Sets up the at-cursor module
function M.setup()
  log.debug("Setting up at-cursor")
  commands:add_commands(module_subcommands)
  keymaps:add_keymaps(module_keymaps)
  if auto_popup.enable then
    setup_auto_popup()
  end
end

return M
