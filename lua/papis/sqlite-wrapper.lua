--
-- PAPIS | SQLITE-WRAPPER
--
--
-- Wrapper around sqlite.lua setting up the main database and associated methods.
--

local log = require("papis.log")

local has_sqlite, _ = pcall(require, "sqlite")
if not has_sqlite then
  log.error("The dependency 'sqlite.nvim' is missing. Ensure that it is installed to run papis.nvim")
  return nil
end

local sqlite = require("sqlite.db") --- for constructing sql databases

local Path = require("pathlib")
local config = require("papis.config")
local db_uri = Path(config["db_path"])
local data_tbl_schema = config["data_tbl_schema"]

if not db_uri:exists() then
  db_uri:parent():mkdir()
end

local tbl_methods = {}

---General sqlite get function
---@param tbl table #The table to query
---@param where? table #The sqlite where clause defining which rows' data to return
---@param select? table #The sqlite select statement defining which columns to return
---@return table #Has structure { { col1 = value1, col2 = value2 ... } ... } giving queried data
function tbl_methods.get(tbl, where, select)
  return tbl:__get({
    where = where,
    select = select,
  })
end

---General sqlite get single value function
---@param tbl table #The table to query
---@param where table #The sqlite where clause defining which rows' data to return
---@param key string #The key of which to return the value
---@return unknown #The value queried
function tbl_methods.get_value(tbl, where, key)
  if type(key) ~= "string" then
    error("get_value() needs to be be called with a single key name")
  end
  local result = tbl:__get({
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
---@param tbl table #The table to update
---@param where table #The sqlite where clause defining which rows' data to return
---@param new_values table #The new row to be inserted
---@return boolean #Whether update successful
function tbl_methods.update(tbl, where, new_values)
  return tbl:__update({
    where = where,
    set = new_values,
  })
end

local M = sqlite({
  uri = tostring(db_uri),
  opts = { busy_timeout = 30000 },
})

-- the main data table
M.data = M:tbl("data", data_tbl_schema)

-- the metadata table
M.metadata = M:tbl("metadata", {
  id = { "integer", pk = true },
  path = { "text", required = true, unique = true },
  mtime = { "integer", required = true }, -- mtime of the info_yaml
  entry = {
    type = "integer",
    reference = "data.id",
    on_update = "cascade",
    on_delete = "cascade",
  },
})

-- the state table
M.state = M:tbl("state", {
  id = true,
  fw_running = { "integer", default = nil },
  tag_format = { "text", default = nil },
})

M.config = M:tbl("config", {
  id = true,
  info_name = { "text", default = nil },
  notes_name = { "text", default = nil },
  dir = { "text", default = nil },
})

---Adds common methods to tbls
---@param tbls table #Set of tables that should have methods added
function M.add_tbl_methods(tbls)
  for _, tbl in pairs(tbls) do
    for method_name, method in pairs(tbl_methods) do
      tbl[method_name] = method
    end
  end
end

M.add_tbl_methods({ M.data, M.metadata, M.state, M.config })

---Updates a row, deleting fields that don't exist in `new_row`
---@param tbl_name string #The table to update
---@param where table #The sqlite where clause defining which rows' data to return
---@param new_values table #The new row to be inserted
function M:clean_update(tbl_name, where, new_values)
  local id = self[tbl_name]:get_value(where, "id")

  local row = self[tbl_name]:__get({
    where = where,
  })[1]

  local fields_to_del = {}
  for col, _ in pairs(row) do
    if not new_values[col] and (col ~= "id") then
      table.insert(fields_to_del, col)
    end
  end

  for _, col in ipairs(fields_to_del) do
    self:with_open(function()
      return self:execute([[update ]] .. tbl_name .. [[ set ]] .. col .. [[ = null where id = ]] .. id .. [[;]])
    end)
  end

  self[tbl_name]:update(where, new_values)
end

---Gets the pid of the neovim instance that is running file watchers
---@return number? #Pid of the relevant process if they are running, nil if not
function M.state:get_fw_running()
  local is_running
  if not self:empty() then
    is_running = tbl_methods.get_value(self, { id = 1 }, "fw_running")
    if is_running == 0 then
      is_running = nil
    end
  end
  return is_running
end

---Sets the pid of the neovim process running file watchers
---@param pid? number #pid of the neovim instance
function M.state:set_fw_running(pid)
  pid = pid or 0
  tbl_methods.update(self, { id = 1 }, { fw_running = pid })
end

---Checks if the config database is setup
function M.config:is_setup()
  local papis_py_conf = M.config:get()
  if vim.tbl_isempty(papis_py_conf) then
    return false
  else
    for _, value in pairs(papis_py_conf[1]) do
      if value == nil or value == '' then
        return false
      end
    end
  end
  return true
end

return M
