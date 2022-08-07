--
-- PAPIS | SEARCH
--
-- Initialises the papis.nvim search module.
--

local log = require("papis.logger")
local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
	log:error("The plugin telescope.nvim wasn't found but the search module is enabled and requires it.")
	return nil
end
local config = require("papis.config")

local M = {}

---Sets up the papis.nvim telescope extension
function M.setup()
	log:debug("Search: setting up module")
	require("papis.search.data").init()
	telescope.setup({
		extensions = {
			papis = config["search"],
		},
	})
	telescope.load_extension("papis")
end

return M
