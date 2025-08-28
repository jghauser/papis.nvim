--
-- PAPIS | SQLITE-WRAPPER
--
--
-- Wrapper around sqlite.lua setting up the main database and associated methods.
--

---@module 'sqlite'

---@alias SqliteSchemaDict sqlite_schema_key|boolean|string

local fs = vim.fs
local uv = vim.uv

local log = require("papis.log")
local has_sqlite, sqlite = pcall(require, "sqlite")
if not has_sqlite then
  error("The dependency 'sqlite.nvim' is missing. Ensure that it is installed to run papis.nvim")
end
local sqlite_utils = require("sqlite.utils")

local config = require("papis.config")
local db_uri = config.db_path
local papis_conf_keys = config.papis_conf_keys

if not uv.fs_stat(db_uri) then
  local parent_dir = fs.dirname(db_uri)
  if not uv.fs_stat(parent_dir) then
    uv.fs_mkdir(parent_dir, 493)
  end
end

---Queries Papis to get various options.
---@return table<string, string> papis_py_conf A table with Papis configuration fields: { info_name = val, dir = val }
local function get_papis_py_conf()
  local papis_py_conf = {}
  for _, key in ipairs(papis_conf_keys) do
    local cmd = vim.list_extend(vim.deepcopy(config.papis_cmd_base), { "config", key })
    local result = vim.system(cmd, { text = true }):wait()

    if result.code == 0 and result.stdout then
      papis_py_conf[string.gsub(key, "-", "_")] = string.gsub(result.stdout, "\n", "")
    else
      vim.notify(string.format("Failed to get papis config for key '%s': %s", key, result.stderr or "unknown error"),
        vim.log.levels.WARN)
    end
  end
  if papis_py_conf.dir then
    local dir = papis_py_conf.dir
    if string.sub(dir, 1, 1) == "~" then
      dir = os.getenv("HOME") .. string.sub(dir, 2, #dir)
    end
    papis_py_conf.dir = dir
  end
  return papis_py_conf
end

---Table that contains all table methods (defined below)
---@class PapisTblMethods
---@field for_each table Methods available to all tables
---@field state table Methods available to the state table
---@field config table Methods available to the config table
local tbl_methods = {
  for_each = {},
  state = {},
  config = {},
}

---@alias SqliteRow
---| table<string, string>

---@alias SqliteWhere
---| table<string, string>

---@alias SqliteSelect
---| string[]

---General sqlite get function
---@class PapisForEachGet
---@param where? SqliteWhere The sqlite where clause defining which rows' data to return
---@param select? SqliteSelect The sqlite select statement defining which columns to return
---@return SqliteRow[] #Has structure { { col1 = value1, col2 = value2 ... } ... } giving queried data
function tbl_methods.for_each:get(where, select)
  return self:__get({
    where = where,
    select = select,
  })
end

---General sqlite get single value function
---@class PapisForEachGetValue
---@param where SqliteWhere The sqlite where clause defining which rows' data to return
---@param key string The key of which to return the value
---@return unknown result The value queried
function tbl_methods.for_each:get_value(where, key)
  if type(key) ~= "string" then
    error("get_value() needs to be be called with a single key name")
  end
  local result = self:__get({
    where = where,
    select = { key },
  })
  if vim.tbl_isempty(result) then
    result = nil
  else
    result = result[1][key]
  end
  return result
end

---Updates a row
---@class PapisForEachUpdate
---@param where SqliteWhere The sqlite where clause defining which rows' data to return
---@param new_values SqliteRow The new row to be inserted
---@return boolean #Whether update successful
function tbl_methods.for_each:update(where, new_values)
  return self:__update({
    where = where,
    set = new_values,
  })
end

---Updates a row, deleting fields that don't exist in `new_row`
---@class PapisForEachCleanUpdate
---@param where SqliteWhere The sqlite where clause defining which rows' data to return
---@param new_values SqliteRow The new row to be inserted
function tbl_methods.for_each:clean_update(where, new_values)
  local id = self:get_value(where, "id")
  new_values.id = id
  self:remove(where)
  self:insert(new_values)
end

---Gets config from Papis and updates the config table with it
---@class PapisConfigUpdate
function tbl_methods.config:update()
  local papis_py_conf_new = get_papis_py_conf()
  self:remove({ id = 1 })
  self:__update({ where = { id = 1 }, set = papis_py_conf_new })
end

---Gets config from Papis and updates the config table with it
---@class PapisConfigGetConfValue
function tbl_methods.config:get_conf_value(key)
  return self:get_value({ id = 1 }, key)
end

---Gets the pid of the neovim instance that is running file watchers
---@class PapisStateGetFWRunning
---@return number? is_running Pid of the relevant process if they are running, nil if not
function tbl_methods.state:get_fw_running()
  local is_running
  if not self:empty() then
    is_running = self:get_value({ id = 1 }, "fw_running")
    if is_running == 0 then
      is_running = nil
    end
  end
  return is_running
end

---Sets the pid of the neovim process running file watchers
---@class PapisStateSetFWRunning
---@param pid? number #pid of the neovim instance
function tbl_methods.state:set_fw_running(pid)
  pid = pid or 0
  self:update({ id = 1 }, { fw_running = pid })
end

---Creates the schema of the config table
---@return SqliteSchemaDict[] tbl_schema The config table schema
local function get_config_tbl_schema()
  ---@type table<string, boolean|table>
  local tbl_schema = { id = true, }
  for _, key in ipairs(config.papis_conf_keys) do
    local sanitized_key = string.gsub(key, "-", "_")
    tbl_schema[sanitized_key] = { "text" }
  end
  return tbl_schema
end

---Checks whether the schema has changed.
---@param new_schema SqliteSchemaDict[] The new schema
---@param old_schema SqliteSchemaDict[] The old schema
---@return boolean #True if schema has changed, false otherwise
local function has_schema_changed(new_schema, old_schema)
  ---@type string[]
  local old_schema_okays = sqlite_utils.okeys(old_schema)
  ---@type string[]
  local new_schema_okays = sqlite_utils.okeys(new_schema)
  if not vim.deep_equal(old_schema_okays, new_schema_okays) then
    return true
  else
    for _, schema_key in pairs(new_schema_okays) do
      local normalised_value = {}
      -- this is not the type that is assigned to the key in the schema
      local new_schema_key = new_schema[schema_key]
      if type(new_schema_key) == "boolean" then
        -- this is what `true` corresponds to
        if type(new_schema_key) == true then
          normalised_value = { type = "INTEGER", primary = true, required = true }
        end
      elseif type(new_schema_key) == "string" then
        -- exception because 'luatable' is always with small letters
        if new_schema_key ~= "luatable" then
          new_schema_key = string.upper(new_schema_key)
        end
        normalised_value.type = new_schema_key
      else
        for k, v in pairs(new_schema_key) do
          if k == 1 then
            local new_schema_type = v
            -- exception because 'luatable' is always with small letters
            if new_schema_type ~= "luatable" then
              new_schema_type = string.upper(new_schema_type)
            end
            normalised_value.type = new_schema_type
          elseif k == "primary" then
            normalised_value[k] = v
          elseif k == "required" then
            normalised_value[k] = v
          end
        end
        if not vim.tbl_get(new_schema_key, "primary") then
          normalised_value.primary = false
        end
        if not vim.tbl_get(new_schema_key, "required") then
          normalised_value.required = false
        end
      end
      for k, v in pairs(normalised_value) do
        if old_schema[schema_key][k] ~= v then
          return true
        end
      end
    end
  end
  return false
end

---Schemas for all tables
---@class PapisTblSchemas
---@field data SqliteSchemaDict[]
---@field metadata SqliteSchemaDict[]
---@field state SqliteSchemaDict[]
---@field config SqliteSchemaDict[]
local schemas = {
  data = config.data_tbl_schema,
  metadata = {
    id = { "integer", primary = true },
    path = { "text", required = true, unique = true },
    mtime = { "integer", required = true }, -- mtime of the info_yaml
    entry = {
      type = "integer",
      reference = "data.id",
      on_update = "cascade",
      on_delete = "cascade",
      required = true,
    },
  },
  state = {
    id = true,
    fw_running = { "integer" },
    db_last_modified = { "integer", default = os.time() },
  },
  config = get_config_tbl_schema(),
}

---@class PapisDataTable : sqlite_tbl
---@field get PapisForEachGet
---@field get_value PapisForEachGetValue
---@field update PapisForEachUpdate
---@field clean_update PapisForEachCleanUpdate

---@class PapisMetadataTable : sqlite_tbl
---@field get PapisForEachGet
---@field get_value PapisForEachGetValue
---@field update PapisForEachUpdate
---@field clean_update PapisForEachCleanUpdate

---@class PapisStateTable : sqlite_tbl
---@field get PapisForEachGet
---@field get_value PapisForEachGetValue
---@field update PapisForEachUpdate
---@field clean_update PapisForEachCleanUpdate
---@field get_fw_running PapisStateGetFWRunning
---@field set_fw_running PapisStateSetFWRunning

---@class PapisConfigTable : sqlite_tbl
---@field get PapisForEachGet
---@field get_value PapisForEachGetValue
---@field update PapisConfigUpdate
---@field clean_update PapisForEachCleanUpdate
---@field get_conf_value PapisConfigGetConfValue

---Create the db
---@class sqlite_db
---@field data PapisDataTable
---@field metadata PapisMetadataTable
---@field state PapisStateTable
---@field config PapisConfigTable
---@field completion? table
local M = sqlite({
  uri = db_uri,
  opts = { busy_timeout = 30000 },
})

---Creates a sqlite table with methods
---@param tbl_name string The name of the table
---@return table tbl The table with methods
function M:create_tbl_with_methods(tbl_name)
  local tbl = self:tbl(tbl_name, schemas[tbl_name])
  for method_name, method in pairs(tbl_methods.for_each) do
    tbl[method_name] = method
  end
  if tbl_methods[tbl_name] then
    for method_name, method in pairs(tbl_methods[tbl_name]) do
      tbl[method_name] = method
    end
  end
  return tbl
end

---Intialises the database
function M:init()
  self:open(db_uri)
  local ask_user_to_reload_data = false
  for tbl_name, new_schema in pairs(schemas) do
    local old_schema = self:schema(tbl_name)
    if self:exists(tbl_name) and (not has_schema_changed(new_schema, old_schema)) then
      self[tbl_name] = self:create_tbl_with_methods(tbl_name)
    else
      log.debug(string.format("The table schema for '%s' has changed", tbl_name))
      if self:exists(tbl_name) then
        self:drop(tbl_name)
        self[tbl_name] = self:create_tbl_with_methods(tbl_name)
      end
      self[tbl_name] = self:create_tbl_with_methods(tbl_name)
      if tbl_name == "config" then
        self.config:update()
      end
      ask_user_to_reload_data = true
    end
  end
  if ask_user_to_reload_data then
    vim.notify("Papis.nvim needs to reset its database. Please run `:Papis reload data`.", vim.log.levels.WARN)
  end
end

return M
