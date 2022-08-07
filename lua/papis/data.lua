--
-- PAPIS | DATA
--
--
-- Manages the data. Talks to storage and database.
--

local papis_storage = require("papis.papis-storage")
if not papis_storage then
	return nil
end
local enable_modules = require("papis.config")["enable_modules"]
local log = require("papis.logger")
local db = require("papis.sqlite-wrapper")
if not db then
	return nil
end

---Updates the module tables. Either it will update the entries in `ids` or, if
---the module table is empty, all entries
---@param metadata table #Has structure { path = path, mtime = mtime }
local function update_module_tbls(metadata)
	for module_name, _ in pairs(enable_modules) do
		local has_module, module = pcall(require, "papis." .. module_name .. ".data")
		if has_module then
			log:debug(string.format("Updating module '%s' sqlite table", module_name))
			module_name = string.gsub(module_name, "-", "_")
			if module["opts"]["has_row_for_each_main_tbl_row"] then
				-- this is to handle modules newly activated
				if db[module_name]:empty() then
					db["data"]:each(function(row)
						db[module_name]:update(row.id)
					end)
				else
					-- we're adding or editing an entry (deletions cascade)
					if metadata["mtime"] then
						local id = db.metadata:get_value({ path = metadata["path"] }, { "entry" })
						db[module_name]:update(id)
					end
				end
			else
				db[module_name]:update()
			end
		end
	end
end

---Updates the main tables for an entry specified by `metadata`
---@param metadata table #Has structure { path = path, mtime = mtime }
local function update_main_tbls(metadata)
	log:debug("Updating main tables")
	if metadata["mtime"] then
		log:debug("Changing/Adding an entry")
		local entry_full_data = papis_storage.get_data_full({ metadata })[1]
		log:debug("Update/Add entry with following data: " .. vim.inspect(entry_full_data))
		if entry_full_data then
			local ref = entry_full_data[1]["ref"]
			local data_row = entry_full_data[1]
			local metadata_row = entry_full_data[2]
			local id = db.data:get({ ref = ref }, { "id" })
			if not vim.tbl_isempty(id) then
				log:debug("Changing an existing entry")
				id = id[1]["id"]
				db:clean_update("data", { id = id }, data_row)
				db.metadata:update({ id = id }, metadata_row)
			else
				log:debug("Adding a new entry")
				id = db.data:insert(data_row)
				metadata_row["entry"] = id
				-- check if entry already exists (can happen because fs watcher sends multiple events)
				if vim.tbl_isempty(db.metadata:__get({ where = { entry = id } })) then
					db.metadata:insert(metadata_row)
				end
			end
		end
	-- we're deleting an entry
	else
		log:debug("Deleting an entry")
		local id = db.metadata:get_value({ path = metadata["path"] }, { "entry" })
		if id then
			db.data:remove({ id = id })
			-- HACK because `on_delete = cascade` doesn't work
			db.metadata:remove({ entry = id })
			for module_name, _ in pairs(enable_modules) do
				module_name = string.gsub(module_name, "-", "_")
				local has_module, module = pcall(require, "papis." .. module_name .. ".data")
				if has_module and module["opts"]["has_row_for_each_main_tbl_row"] then
					db[module_name]:remove({ entry = id })
				end
			end
		end
	end
end

---Synchronises the main data and metadata tables from storage files and inits
---updates in module tables
local function sync_storage_data()
	local new_metadata = papis_storage.get_metadata()
	local old_metadata = db.metadata:get()
	local old_metadata_ass = {}
	for _, metadata_entry in ipairs(old_metadata) do
		old_metadata_ass[metadata_entry["path"]] = metadata_entry["mtime"]
	end
	local new_metadata_ass = {}
	for _, metadata_entry in ipairs(new_metadata) do
		new_metadata_ass[metadata_entry["path"]] = metadata_entry["mtime"]
	end
	-- handle deleted files
	for _, metadata_entry in ipairs(old_metadata) do
		local path_old = metadata_entry["path"]
		if not new_metadata_ass[path_old] then
			log:debug("An entry on disk has been deleted. Remove from database...")
			metadata_entry = { path = path_old, mtime = nil }
			update_main_tbls(metadata_entry)
			update_module_tbls(metadata_entry)
		end
	end
	-- handle changed and new files
	for _, metadata_entry in ipairs(new_metadata) do
		local mtime_new = metadata_entry["mtime"]
		local mtime_old = old_metadata_ass[metadata_entry["path"]]
		if mtime_new ~= mtime_old then
			log:debug("An entry on disk is new or has changed. Updating from yaml...")
			update_main_tbls(metadata_entry)
			update_module_tbls(metadata_entry)
		end
	end
end

local M = {}

---Updates the database for a given entry specified by `metadata`
---@param metadata table #Has structure { path = path, mtime = mtime } and specifies the entry
function M.update_db(metadata)
	log:debug("Updating the database")
	update_main_tbls(metadata)
	update_module_tbls(metadata)
end

---Resets the database
function M:reset_db()
	db.data:drop()
	db.metadata:drop()
	-- HACK because `on_delete = cascade` doesn't work
	for module_name, _ in pairs(enable_modules) do
		module_name = string.gsub(module_name, "-", "_")
		local has_module, _ = pcall(require, "papis." .. module_name .. ".data")
		if has_module then
			db[module_name]:drop()
		end
	end
	self:sync_db()
end

---Synchronises the database
function M:sync_db()
	log:debug("Synchronising database...")
	sync_storage_data()
end

return M
