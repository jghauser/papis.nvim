--
-- PAPIS | FORMATTER
--
--
-- This modules formats new notes created by papis.nvim using a template function.
--

local log = require("papis.logger")

local create_autocmd = vim.api.nvim_create_autocmd
local create_augroup = vim.api.nvim_create_augroup

local M = {}

function M.create_autocmd(pattern, callback, entry)
	local papisFormatter = create_augroup("papisFormatter", { clear = true })
	create_autocmd("BufEnter", {
		pattern = pattern,
		callback = function()
			log.debug("Running formatter callback...")
			callback(entry)
		end,
		group = papisFormatter,
		once = true,
		desc = "Papis: format a newly created note",
	})
end

return M
