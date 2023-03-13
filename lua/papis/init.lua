--
-- PAPIS | INIT
--
--
-- Sets up papis.nvim.
--

local config = require("papis.config")
local api = vim.api

local log

---Creates the `autocmd` that starts papis.nvim when configured conditions are fulfilled
local function make_start_autocmd()
	local load_papis = api.nvim_create_augroup("loadPapis", { clear = true })
	api.nvim_create_autocmd("BufEnter", {
		pattern = config["init_filenames"],
		callback = require("papis").start,
		group = load_papis,
		desc = "Load papis.nvim for defined filenames",
	})
end

local M = {}

---This function is run when neovim starts. It sets up the `PapisStart` command and autocmd
---to allow lazy-loading of papis.nvim.
---@param opts table #User configuration
function M.setup(opts)
	-- update config with user config
	config:update(opts)

	log = require("papis.logger")

	if not vim.fn.executable("papis") then
		log.error("The command 'papis' could not be found. Papis must be installed to run papis.nvim")
		return nil
	end

	log.debug("_________________________SETTING UP PAPIS.NVIM_________________________")
	log.debug("Creating `PapisStart` command")
	require("papis.commands").setup("init")
	-- make_papis_start()
	log.debug("Creating autocmds to lazily load papis.nvim")
	make_start_autocmd()
end

---This function starts all of papis.nvim.
function M.start()
	log.debug("Starting papis.nvim")

	-- delete command that starts papis
	vim.api.nvim_del_user_command("PapisStart")

	-- delete autocmd that starts papis
	vim.api.nvim_del_augroup_by_name("loadPapis")

	-- require what's necessary within `M.start()` instead of globally to allow lazy-loading
	local db = require("papis.sqlite-wrapper")
	if not db then
		log.warn("Requiring `sqlite-wrapper.lua` failed. Aborting...")
		return nil
	end
	local data = require("papis.data")
	if not data then
		log.warn("Requiring `data.lua` failed. Aborting...")
		return nil
	end
	local does_pid_exist = require("papis.utils").does_pid_exist

	-- get all functions that we need to run the various commands
	for module_name, is_enabled in pairs(config["enable_modules"]) do
		if is_enabled then
			log.trace(module_name .. " is enabled")
			local has_module, module = pcall(require, "papis." .. module_name)
			-- local module = require("papis." .. module_name)
			if has_module then
				if module["setup"] then
					module.setup()
				end
			end
		end
	end

	log.debug("Setting up commands and keymaps")
	-- setup commands
	if config["enable_commands"] then
		require("papis.commands").setup()
	end
	-- setup keymaps
	if config["enable_keymaps"] then
		require("papis.keymaps").setup()
	end

	-- check if other neovim instances has file watchers
	if not does_pid_exist(db.state:get_fw_running()) then
		-- setup file watchers (or an autocmd if another instance has file watchers)
		if config["enable_fs_watcher"] then
			require("papis.fs-watcher"):init()
		end

		log.debug("Synchronising the database")
		data:sync_db()
	else
		-- setup file watchers (or an autocmd if another instance has file watchers)
		if config["enable_fs_watcher"] then
			require("papis.fs-watcher"):init()
		end
	end

	log.debug("Papis.nvim up and running")
end

return M
