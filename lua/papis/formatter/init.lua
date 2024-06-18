--
-- PAPIS | FORMATTER
--
--
-- This modules formats new notes created by papis.nvim using a template function.
--

local log = require("papis.log")

local create_autocmd = vim.api.nvim_create_autocmd
local create_augroup = vim.api.nvim_create_augroup

local augroup = create_augroup("papisFormatter", { clear = true })
local autocmd = {
  pattern = nil,
  callback = nil,
  group = augroup,
  once = true,
  desc = "Papis: format a newly created note",
}

local M = {}

function M.create_autocmd(pattern, callback, entry)
  autocmd.pattern = pattern
  autocmd.callback = function()
    log.debug("Running formatter callback...")
    callback(entry)
  end
  create_autocmd("BufEnter", autocmd)
end

return M
