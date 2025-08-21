--
-- PAPIS | PAPIS-STORAGE
--
--
-- Reads out all the Papis yaml files and creates data ready for db
--

local Path = require("pathlib")

local fs_stat = vim.uv.fs_stat

local db = assert(require("papis.sqlite-wrapper"), "Failed to load papis.sqlite-wrapper")
local log = require("papis.log")
local config = require("papis.config")
local data_tbl_schema = config.data_tbl_schema
local key_name_conversions = config["papis-storage"].key_name_conversions
local required_keys = config["papis-storage"].required_keys
local yq_bin = config.yq_bin

---Checks if a decoded entry is valid
---@param entry table|nil #The entry as a table or nil if entry wasn't read properly before
---@param path string #The path to the info file
---@return boolean #True if valid entry, false otherwise
local function is_valid_entry(entry, path)
  local is_valid = true
  if entry then
    for _, key in ipairs(required_keys) do
      if not entry[key] then
        vim.notify(string.format("The entry at '%s' is missing the key '%s' and will not be added.", path, key),
          vim.log.levels.WARN)
        is_valid = false
      end
    end
  else
    vim.notify(string.format("The entry at '%s' is faulty and will not be added.", path), vim.log.levels.WARN)
    is_valid = false
  end
  return is_valid
end

---Reads the info file at the path, converts it to json and decodes that
---@param path string #The path to the info file
---@return table|nil #The entry as a table, or nil if something goes wrong
local function read_yaml(path)
  log.trace("Reading path: " .. path)
  local entry
  local filepath = Path(path)
  local handler = io.popen(yq_bin .. ' -oj "' .. tostring(filepath) .. '" 2>/dev/null')
  if handler then
    local as_json = handler:read("*all")
    handler:close()
    local ok, decoded_entry = pcall(vim.json.decode, as_json, { luanil = { object = true, array = true } })
    -- only add an entry if the yaml file could be decoded without issues
    if ok then
      entry = decoded_entry
    else
      vim.notify(string.format("Failed to decode JSON for the file at '%s'.", path), vim.log.levels.WARN)
    end
  else
    vim.notify(string.format("Failed to read the file at '%s'.", path), vim.log.levels.WARN)
  end
  return entry
end

---Converts the names of certain keys in an entry to the format expected
---by papis.nvim
---@param entry table #The entry as read from the info file
---@return table #The entry with converted key names
local function do_convert_entry_keys(entry)
  for key_tbl, key_storage in pairs(key_name_conversions) do
    if entry[key_storage] then
      entry[key_tbl] = entry[key_storage]
    end
  end

  return entry
end

---Creates full paths from filenames and a path
---@param filenames string|table #Filename as string if single path, otherwise table of filename strings
---@param path string #Path to files
---@return table #Table of string with full paths
local function make_full_paths(filenames, path)
  if type(filenames) == "string" then
    filenames = { filenames }
  end

  local full_paths = {}
  for _, filename in ipairs(filenames) do
    local full_path = tostring(Path(path, filename))
    full_paths[#full_paths + 1] = full_path
  end
  return full_paths
end

local M = {}

---This function gets mtime of info_name files in a specific path or in all paths
---@param paths? table #A list with paths of papis entries
---@return table #A list of { path = path, mtime = mtime } values
function M.get_metadata(paths)
  local library_dir = Path(db.config:get_conf_value("dir"))
  local info_name = db.config:get_conf_value("info_name")
  if not paths then
    paths = {}
    for path in library_dir:fs_iterdir() do
      if path:basename() == info_name then
        paths[#paths + 1] = path
      end
    end
  end
  local metadata = {}
  for _, path in ipairs(paths) do
    local mtime = fs_stat(tostring(path)).mtime.sec
    metadata[#metadata + 1] = { path = tostring(path), mtime = mtime }
  end
  return metadata
end

---This function is used to get info for some or all papis entries. Only valid entries are returned.
---@param metadata? table #A list with { path = path, mtime = mtime } values
---@return table #A list of {{ papis_id = papis_id, key = val, ...}, { path = path, mtime = mtime }} values.
function M.get_data_full(metadata)
  metadata = metadata or M.get_metadata()
  local data_complete = {}
  for _, metadata_v in ipairs(metadata) do
    local path = metadata_v.path
    local mtime = metadata_v.mtime
    local entry = read_yaml(path)
    if is_valid_entry(entry, path) then
      entry = do_convert_entry_keys(entry) --NOTE: entry is never nil because of `is_valid_entry()`
      local data = {}
      for key, type_of_val in pairs(data_tbl_schema) do
        if type(type_of_val) == "table" then
          type_of_val = type_of_val[1]
        end
        if entry[key] then
          -- determine tag_format when first coming across tags and format tags as table
          if key == "tags" then
            if type(entry[key]) ~= "table" then
              error(
                "The tag format isn't a list. Please convert your info.yaml files with `papis doctor -t key-type` to use papis.nvim.")
            end
          end
          if (key == "files") or (key == "notes") then
            local entry_path = Path(path):parent()
            entry[key] = make_full_paths(entry[key], entry_path)
          end

          -- ensure that everything is of the correct type
          if type_of_val == "text" then
            -- convert value to string and remove stray control characters
            data[key] = string.gsub(tostring(entry[key]), "[%c]", "")
          elseif type_of_val == "luatable" then
            if type(entry[key]) == "table" then
              data[key] = entry[key]
            else
              vim.notify("Wanted to add `" .. key .. "` of `" .. entry.ref .. "` but the value is not of type `table`",
                vim.log.levels.WARN)
              data[key] = {}
            end
          end
        end
      end
      data_complete[#data_complete + 1] = { data, { path = path, mtime = mtime } }
    end
  end
  return data_complete
end

return M
