--
-- PAPIS | PAPIS-STORAGE
--
--
-- Reads out all the Papis yaml files and creates data ready for db
--

local Path = require("plenary.path")
local Scan = require("plenary.scandir")

local fs_stat = vim.loop.fs_stat

local db = require("papis.sqlite-wrapper")
if not db then
  return nil
end
local utils = require("papis.utils")
local log = require("papis.logger")
local config = require("papis.config")
local library_dir = (Path:new(config["papis_python"]["dir"]))
local info_name = config["papis_python"]["info_name"]
local data_tbl_schema = config["data_tbl_schema"]
local key_name_conversions = config["papis-storage"]["key_name_conversions"]
local tag_format = config["papis-storage"]["tag_format"]
local have_determined_tag_format = false
local yq_bin = config["yq_bin"]

--- This function determines if tag format is list, space separated, or comma separated
---@param tags any #Either a table or a string with tag(s)
local function do_determine_tag_format(tags)
  if type(tags) == "table" then
    tag_format = "tbl"
    have_determined_tag_format = true
  elseif string.find(tags, ",") then
    tag_format = ","
    have_determined_tag_format = true
  elseif string.find(tags, ";") then
    tag_format = ";"
    have_determined_tag_format = true
  elseif string.find(tags, " ") then
    tag_format = " "
    have_determined_tag_format = true
  end
end

---This function converts, if necessary, the tags into a table.
---@param tags any #Either a table or a string with tag(s)
---@return table #A table with tags
local function ensure_tags_are_tbl(tags)
  -- we haven't determined it, it must be a single string tag
  if not have_determined_tag_format then
    tags = { tags }
  -- if it's a table we don't need to do anything
  elseif tag_format == "tbl" then
  -- otherwise split the string
  else
    tags = utils.do_split_str(tags, tag_format)
  end
  return tags
end

local function is_valid_entry(entry, path)
  if entry["ref"] then
    return true
  else
    log.info(string.format("The entry at '%s' is missing a reference and is not added to the database.", path))
    return false
  end
end

local function read_yaml(path)
  log.trace("Reading path: " .. path)
  local filepath = Path:new(path)
  local as_json = io.popen(yq_bin .. ' -oj "' .. filepath:absolute() .. '"'):read("*all")
  local entry = vim.json.decode(as_json)
  return entry
end

local function do_convert_entry_keys(entry)
  for key_tbl, key_storage in pairs(key_name_conversions) do
    if entry[key_storage] then
      entry[key_tbl] = entry[key_storage]
    end
  end

  return entry
end

local function make_full_paths(filenames, path)
  if type(filenames) == "string" then
    filenames = { filenames }
  end

  local full_paths = {}
  for _, filename in ipairs(filenames) do
    local full_path = Path:new(path, filename):expand()
    table.insert(full_paths, full_path)
  end
  return full_paths
end

local M = {}

---Gets the opts determined by the papis-storage module
---@return table #A table of { k = v, ... } format
function M.get_state()
  return { tag_format = tag_format }
end

---This function gets mtime of info_name files in a specific path or in all paths
---@param paths? table #A list with paths of papis entries
---@return table #A list of { path = path, mtime = mtime } values
function M.get_metadata(paths)
  paths = paths or Scan.scan_dir(library_dir:expand(), { depth = 2, search_pattern = info_name })
  local metadata = {}
  for _, path in ipairs(paths) do
    local mtime = fs_stat(path).mtime.sec
    -- path = Path:new(path)
    -- path = path:parent():absolute()
    table.insert(metadata, { path = path, mtime = mtime })
  end
  return metadata
end

---This function is used to get info for some or all papis entries. Only valid entries are returned.
---@param metadata? table #A list with { path = path, mtime = mtime } values
---@return table #A list of {{ ref = ref, key = val, ...}, { path = path, mtime = mtime }} values.
function M.get_data_full(metadata)
  metadata = metadata or M.get_metadata()
  local data_complete = {}
  for _, metadata_v in ipairs(metadata) do
    local path = metadata_v["path"]
    local mtime = metadata_v["mtime"]
    local entry = read_yaml(path)
    if is_valid_entry(entry, path) then
      entry = do_convert_entry_keys(entry)
      local data = {}
      for key, type_of_val in pairs(data_tbl_schema) do
        if type(type_of_val) == "table" then
          type_of_val = type_of_val[1]
        end
        if entry[key] then
          -- determine tag_format when first coming across tags and format tags as table
          if key == "tags" then
            if not have_determined_tag_format then
              do_determine_tag_format(entry[key])
            else
              db.state:update({ id = 1 }, { tag_format = tag_format })
            end
            entry[key] = ensure_tags_are_tbl(entry[key])
          end
          if (key == "files") or (key == "notes") then
            local entry_path = Path:new(path):parent()
            entry[key] = make_full_paths(entry[key], entry_path)
          end

          -- ensure that everything is of the correct type
          if type_of_val == "text" then
            data[key] = tostring(entry[key])
          elseif type_of_val == "luatable" then
            if type(entry[key]) == "table" then
              data[key] = entry[key]
            else
              log.warn("Wanted to add `" .. key .. "` of `" .. entry["ref"] .. "` but the value is not of type `table`")
              data[key] = {}
            end
          end
        end
      end
      table.insert(data_complete, { data, { path = path, mtime = mtime } })
    end
  end
  return data_complete
end

return M
