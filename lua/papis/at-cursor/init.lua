--
-- PAPIS | AT-CURSOR
--
--
-- Various functionalities when the cursor is over a citation reference.
--

local NuiPopup = require("nui.popup")
local nuiAutocmd = require("nui.utils.autocmd")
local nuiEvent = require("nui.utils.autocmd").event

local fn = vim.fn

local log = require("papis.log")
local config = require("papis.config")
local popup_format = config["at-cursor"]["popup_format"]
local utils = require("papis.utils")
local commands = require("papis.commands")
local keymaps = require("papis.keymaps")
local db = require("papis.sqlite-wrapper")
if not db then
  return nil
end
local hover_required_db_keys = utils:get_required_db_keys({ popup_format })

---Tries to identify the ref under cursor
---@return string|nil #Nil if nothing is found, otherwise is the identified ref
local function get_ref_under_cursor()
  -- get the word under the cursor
  local ref = fn.expand("<cWORD>")
  local filetype = vim.bo.filetype
  log.debug("The filetype is: " .. filetype)
  local cite_format = utils.get_cite_format(filetype)
  if type(cite_format) == "table" then
    cite_format = cite_format[2]
  end
  log.debug("The cite_format is: " .. cite_format)
  local _, prefix_end = string.find(cite_format, "%%s")
  prefix_end = prefix_end - 2
  local cite_format_prefix = string.sub(cite_format, 1, prefix_end)
  local _, ref_start = string.find(ref, cite_format_prefix)
  -- if we found the cite_format prefix in the string, we need to strip it
  if ref_start then
    ref_start = ref_start + 1
    ref = string.sub(ref, ref_start)
  end
  -- remove all punctuation characters at the beginning and end of string
  ref = ref:gsub("^[%p]*(.-)[%p]*$", "%1")

  return ref
end

---Runs function if there is a valid ref under cursor which exists in the database
---@param fun function #The function to be run with the papis_id
---@param self? table #Self argument to be passed to fun
---@param type? string #Type argument to be passed to fun
local function if_ref_valid_run_fun(fun, self, type)
  local ref = get_ref_under_cursor()
  local entry = db.data:get({ ref = ref }, { "papis_id" })
  if not vim.tbl_isempty(entry) then
    local papis_id = entry[1]["papis_id"]
    if self then
      fun(self, papis_id, type)
    else
      fun(papis_id, type)
    end
  else
    log.info(string.format("No entry in database corresponds to '%s'", ref))
  end
end

---Creates a popup with information regarding the entry specified by `ref`
---@param papis_id string #The `papis_id` of the entry
local function create_hover_popup(papis_id)
  local entry = db.data:get({ papis_id = papis_id }, hover_required_db_keys)[1]
  local clean_popup_format = utils.do_clean_format_tbl(popup_format, entry)
  local popup_lines, width = utils.make_nui_lines(clean_popup_format, entry)

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
  nuiAutocmd.buf.define(bufnr, { nuiEvent.BufLeave, nuiEvent.CursorMoved, nuiEvent.BufWinLeave }, function()
    popup:unmount()
  end, { once = true })

  -- mount/open the component
  popup:mount()

  for line_nr, line in ipairs(popup_lines) do
    line:render(popup.bufnr, -1, line_nr)
  end
end

---@class PapisSubcommand
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
      local reload_args = {
        "open-file",
        "open-note",
        "edit",
        "show-popup",
      }
      return vim.iter(reload_args)
          :filter(function(install_arg)
            return install_arg:find(subcmd_arg_lead) ~= nil
          end)
          :totable()
    end,
  }
}

---@class PapisKeymaps
local module_keymaps = {
  open_file = {
    mode = "n",
    lhs = "<leader>pof",
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
    lhs = "<leader>pon",
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

local M = {}

function M.setup()
  log.debug("Setting up at-cursor")
  commands:add_commands(module_subcommands)
  keymaps:add_keymaps(module_keymaps)
end

return M
