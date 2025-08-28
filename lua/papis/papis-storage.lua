--
-- PAPIS | PAPIS-STORAGE
--
--
-- Reads out all the Papis yaml files and creates data ready for db
--

---@class PapisAuthorList
---@field family string
---@field given string

---These are entries from Papis, with some keys converted to play nice with lua
---@class PapisEntry
---@field papis_id string
---@field ref string
---@field author? string
---@field author_list? PapisAuthorList[]
---@field editor? string
---@field title? string
---@field shorttitle? string
---@field year? integer
---@field type? string
---@field tags? string[]
---@field notes? string[] -- NOTE: this is different from Papis, where notes is a string
---@field time_added? string[] -- NOTE: this is different from Papis, where the key is time-added

---Metadata for a Papis entry
---@class PapisEntryMetadata
---@field path string The path to the info file
---@field mtime integer The mtime of the info file


local uv = vim.uv
local fs = vim.fs

local db = assert(require("papis.sqlite-wrapper"), "Failed to load papis.sqlite-wrapper")
local log = require("papis.log")
local config = require("papis.config")
local data_tbl_schema = config.data_tbl_schema
local key_name_conversions = config["papis-storage"].key_name_conversions
local required_keys = config["papis-storage"].required_keys
local yq_bin = config.yq_bin

---Checks if a decoded entry is valid
---@param raw_entry table? The raw entry as a table or nil if entry wasn't read properly before
---@param path string The path to the info file
---@return table|nil raw_entry True if valid entry, false otherwise
local function validate_entry(raw_entry, path)
  if not raw_entry then
    vim.notify(("The entry at '%s' is faulty and will not be added."):format(path), vim.log.levels.WARN)
    return nil
  end
  for _, key in ipairs(required_keys) do
    if not raw_entry[key] then
      vim.notify(("The entry at '%s' is missing the key '%s' and will not be added."):format(path, key),
        vim.log.levels.WARN)
      return nil
    end
  end
  return raw_entry
end

---Reads the info file at the path, converts it to json and decodes that
---@param path string The path to the info file
---@return table|nil raw_entry The raw entry as a table, or nil if something goes wrong
local function read_yaml(path)
  log.trace("Reading path: " .. path)
  local raw_entry
  local handler = io.popen(yq_bin .. ' -oj "' .. path .. '" 2>/dev/null')
  if handler then
    local as_json = handler:read("*all")
    handler:close()
    local ok, decoded_entry = pcall(vim.json.decode, as_json, { luanil = { object = true, array = true } })
    -- only add an entry if the yaml file could be decoded without issues
    if ok then
      raw_entry = decoded_entry
    else
      vim.notify(string.format("Failed to decode JSON for the file at '%s'.", path), vim.log.levels.WARN)
    end
  else
    vim.notify(string.format("Failed to read the file at '%s'.", path), vim.log.levels.WARN)
  end
  return raw_entry
end

---Converts the names of certain keys in an entry to the format expected by papis.nvim
---@param raw_entry table The entry as read from the info file
---@return PapisEntry entry The entry with converted key names
local function do_convert_entry_keys(raw_entry)
  for key_tbl, key_storage in pairs(key_name_conversions) do
    if raw_entry[key_storage] then
      raw_entry[key_tbl] = raw_entry[key_storage]
    end
  end

  return raw_entry
end

---Creates full paths from filenames and a path
---@param filenames string|string[] Filename as string if single path, otherwise list of filename strings
---@param path string Path to files
---@return string[] full_paths Table of string with full paths
local function make_full_paths(filenames, path)
  if type(filenames) == "string" then
    filenames = { filenames }
  end

  local full_paths = {}
  for _, filename in ipairs(filenames) do
    local full_path = fs.joinpath(path, filename)
    full_paths[#full_paths + 1] = full_path
  end
  return full_paths
end

---@class PapisStorage
local M = {}

---This function gets mtime of info_name files in a specific path or in all paths
---@param paths? string[] A list with paths of papis entries
---@return PapisEntryMetadata metadata A list of { path = path, mtime = mtime } values
function M.get_metadata(paths)
  local library_dir = db.config:get_conf_value("dir")
  local info_name = db.config:get_conf_value("info_name")
  if not paths then
    paths = fs.find({ info_name }, { limit = math.huge, type = "file", path = library_dir })
  end
  local metadata = {}
  for _, path in ipairs(paths) do
    local mtime = uv.fs_stat(path).mtime.sec
    metadata[#metadata + 1] = { path = path, mtime = mtime }
  end
  return metadata
end

---This function is used to get info for some or all papis entries. Only valid entries are returned.
---@param metadata? table<PapisEntryMetadata> list with { path = path, mtime = mtime } values
---@return table<table<PapisEntry, PapisEntryMetadata>> data_complete A list of entries with associated metadata
function M.get_data_full(metadata)
  metadata = metadata or M.get_metadata()
  local data_complete = {}
  for _, metadata_v in ipairs(metadata) do
    local path = metadata_v.path
    local mtime = metadata_v.mtime
    local entry = validate_entry(read_yaml(path), path)
    if entry then
      ---@type PapisEntry
      entry = do_convert_entry_keys(entry)
      local data = {}
      for key, type_of_val in pairs(data_tbl_schema) do
        if type(type_of_val) == "table" then
          type_of_val = type_of_val[1]
        end
        if entry[key] then
          if key == "tags" then
            if type(entry[key]) ~= "table" then
              error(
                "The tag format isn't a list. Please convert your info.yaml files with `papis doctor -t key-type` to use papis.nvim.")
            end
          end
          if (key == "files") or (key == "notes") then
            local entry_path = fs.dirname(path)
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
