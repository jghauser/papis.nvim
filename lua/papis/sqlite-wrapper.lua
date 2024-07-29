--
-- PAPIS | SQLITE-WRAPPER
--
--
-- Wrapper around sqlite.lua setting up the main database and associated methods.
--

local log = require("papis.log")

local has_sqlite, sqlite = pcall(require, "sqlite")
if not has_sqlite then
  log.error("The dependency 'sqlite.nvim' is missing. Ensure that it is installed to run papis.nvim")
  return nil
end
local sqlite_utils = require "sqlite.utils"

local Path = require("pathlib")
local config = require("papis.config")
local db_uri = Path(config.db_path)
local is_testing_session = config.enable_modules["testing"]
local papis_conf_keys = config.papis_conf_keys

if not db_uri:exists() then
  db_uri:parent_assert():mkdir(Path.permission("rwxr-xr-x"), true)
end

---Queries Papis to get various options.
---@return table #A table { info_name = val, dir = val }
local function get_papis_py_conf()
  local papis_py_conf_new = {}
  local testing_conf_path = ""
  if is_testing_session then
    testing_conf_path = "-c ./tests/papis_config "
  end
  for _, key in ipairs(papis_conf_keys) do
    local handle = io.popen("papis " .. testing_conf_path .. "config " .. key)
    if handle then
      papis_py_conf_new[string.gsub(key, "-", "_")] = string.gsub(handle:read("*a"), "\n", "")
      handle:close()
    end
  end
  if papis_py_conf_new.dir then
    local dir = papis_py_conf_new.dir
    if string.sub(dir, 1, 1) == "~" then
      dir = os.getenv("HOME") .. string.sub(dir, 2, #dir)
    end
    papis_py_conf_new.dir = dir
  end
  return papis_py_conf_new
end

---Table that contains all table methods (defined below)
local tbl_methods = {
  for_each = {}, -- all tables get these methods
  state = {},    -- the state table gets these methods
  config = {},   -- the config table gets these methods
}

---General sqlite get function
---@param where? table #The sqlite where clause defining which rows' data to return
---@param select? table #The sqlite select statement defining which columns to return
---@return table #Has structure { { col1 = value1, col2 = value2 ... } ... } giving queried data
function tbl_methods.for_each:get(where, select)
  return self:__get({
    where = where,
    select = select,
  })
end

---General sqlite get single value function
---@param where table #The sqlite where clause defining which rows' data to return
---@param key string #The key of which to return the value
---@return unknown #The value queried
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
---@param where table #The sqlite where clause defining which rows' data to return
---@param new_values table #The new row to be inserted
---@return boolean #Whether update successful
function tbl_methods.for_each:update(where, new_values)
  return self:__update({
    where = where,
    set = new_values,
  })
end

---Updates a row, deleting fields that don't exist in `new_row`
---@param where table #The sqlite where clause defining which rows' data to return
---@param new_values table #The new row to be inserted
function tbl_methods.for_each:clean_update(where, new_values)
  local id = self:get_value(where, "id")
  new_values.id = id
  self:remove(where)
  self:insert(new_values)
end

---Gets config from Papis and updates the config table with it
function tbl_methods.config:update()
  local papis_py_conf_new = get_papis_py_conf()
  self:remove({ id = 1 })
  self:__update({ where = { id = 1 }, set = papis_py_conf_new })
end

---Gets config from Papis and updates the config table with it
function tbl_methods.config:get_conf_value(key)
  return self:get_value({ id = 1 }, key)
end

---Gets the pid of the neovim instance that is running file watchers
---@return number? #Pid of the relevant process if they are running, nil if not
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
---@param pid? number #pid of the neovim instance
function tbl_methods.state:set_fw_running(pid)
  pid = pid or 0
  self:update({ id = 1 }, { fw_running = pid })
end

---Creates the schema of the config table
---@return table #The config table schema
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
---@param new_schema table #The new schema
---@param old_schema table #The old schema
---@return boolean #True if schema has changed, false otherwise
local function has_schema_changed(new_schema, old_schema)
  local old_schema_okays = sqlite_utils.okeys(old_schema)
  local new_schema_okays = sqlite_utils.okeys(new_schema)
  if not vim.deep_equal(old_schema_okays, new_schema_okays) then
    return true
  else
    for _, key in pairs(new_schema_okays) do
      local normalised_value = {}
      if new_schema[key] == true then
        normalised_value = { type = "INTEGER", primary = true, required = true }
      elseif type(new_schema[key]) == "string" then
        local new_schema_type = new_schema[key]
        if new_schema_type ~= "luatable" then
          new_schema_type = string.upper(new_schema_type)
        end
        normalised_value.type = new_schema_type
      else
        for k, v in pairs(new_schema[key]) do
          if k == 1 then
            local new_schema_type = v
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
        if not vim.tbl_get(new_schema[key], "primary") then
          normalised_value.primary = false
        end
        if not vim.tbl_get(new_schema[key], "required") then
          normalised_value.required = false
        end
      end
      for k, v in pairs(normalised_value) do
        if old_schema[key][k] ~= v then
          return true
        end
      end
    end
  end
  return false
end

-- Schemas for all tables
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
    tag_format = { "text" },
    db_last_modified = { "integer", default = os.time() },
  },
  config = get_config_tbl_schema(),
}

-- Create the db
local M = sqlite({
  uri = tostring(db_uri),
  opts = { busy_timeout = 30000 },
})

---Creates a table with methods
---@param tbl_name string #The name of the table
---@return table #The table with methods
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
  self:open()
  local ask_user_to_reload_data = false
  for tbl_name, new_schema in pairs(schemas) do
    local old_schema = self:tbl(tbl_name):schema()
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
