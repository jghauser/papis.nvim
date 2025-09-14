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
  ---Normalizes a single schema entry to a consistent format
  ---@param value any The schema value (boolean, string, or table)
  ---@return table normalized The normalized schema entry
  local function normalize_schema_entry(value)
    local normalized = {
      type = nil,
      primary = false,
      required = false
    }

    if type(value) == "boolean" then
      if value == true then
        normalized.type = "integer"
        normalized.primary = true
        normalized.required = true
      end
    elseif type(value) == "string" then
      -- When value is a string, that string IS the type
      normalized.type = string.lower(value)
    elseif type(value) == "table" then
      -- Handle different table formats
      for k, v in pairs(value) do
        if k == 1 then
          -- Array-style: { "integer", primary = true }
          normalized.type = string.lower(v)
        elseif k == "type" then
          -- Explicit type field: { type = "integer", ... }
          normalized.type = string.lower(v)
        elseif k == "primary" then
          normalized.primary = v
        elseif k == "required" then
          normalized.required = v
          -- Ignore 'unique' and database-specific fields like 'cid', 'reference', 'on_delete', 'on_update'
        end
      end
    end

    return normalized
  end

  ---Normalizes an entire schema table
  ---@param schema table|nil The schema to normalize
  ---@return table normalized The normalized schema
  local function normalize_schema(schema)
    if not schema then
      return {}
    end

    local normalized = {}
    for key, value in pairs(schema) do
      normalized[key] = normalize_schema_entry(value)
    end
    return normalized
  end

  local normalized_new = normalize_schema(new_schema)
  local normalized_old = normalize_schema(old_schema)

  if not vim.deep_equal(normalized_new, normalized_old) then
    log.debug("The table schema has changed")
    log.debug(string.format("Normalized old schema: %s", vim.inspect(normalized_old)))
    log.debug(string.format("Normalized new schema: %s", vim.inspect(normalized_new)))
    return true
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
  for tbl_name, new_schema in pairs(schemas) do
    log.debug(string.format("Creating table '%s'", tbl_name))
    local old_schema = self:schema(tbl_name)
    if self:exists(tbl_name) and (not has_schema_changed(new_schema, old_schema)) then
      self[tbl_name] = self:create_tbl_with_methods(tbl_name)
    else
      if self:exists(tbl_name) then
        self:drop(tbl_name)
        self[tbl_name] = self:create_tbl_with_methods(tbl_name)
      end
      self[tbl_name] = self:create_tbl_with_methods(tbl_name)
      if tbl_name == "config" then
        self.config:update()
      end
      vim.notify("Papis.nvim needs to reset its database. Please run `:Papis reload data`.", vim.log.levels.WARN)
    end
  end
end

return M
