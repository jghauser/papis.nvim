--
-- PAPIS | COMPLETION | DATA
--
--
-- Defines the sqlite table and associated methods for the completion module.
--

local db = require("papis.sqlite-wrapper")
if not db then
  return nil
end

---Makes a list of all tags
---@return table #Has structure { tag1, tag2, ... } and contains all tags
local function get_all_tags()
  local all_tags = {}
  local result = db.data:get(nil, { "tags" })
  for _, entry in pairs(result) do
    if entry["tags"] then
      for _, tag in pairs(entry["tags"]) do
        all_tags[tag] = true
      end
    end
  end
  return vim.tbl_keys(all_tags)
end

---Makes a list of strings ready for use by completion
---@return table #Has structure {{ word = str, label = str, insertText = str, filterText = str } ...}
local function make_completion_items()
  local completion_items = {}
  local tags = get_all_tags()
  for _, tag in ipairs(tags) do
    completion_items[#completion_items + 1] = {
      word = tag,
      label = tag,
    }
  end
  return completion_items
end

---Initialises the sqlite table and associated methods used by the papis.nvim completion module
local function init_tbl()
  db.completion = db:tbl("completion", {
    id = true,
    tag_strings = { "luatable" },
  })

  ---Gets the list of all tags
  ---@return table #Has structure {{ tag_strings = tbl_of_tags }}
  function db.completion:get()
    return self:__get({
      where = { id = 1 },
      select = {
        "tag_strings",
      },
    })
  end

  ---Updates the list of all tags
  function db.completion:update(_)
    local completion_items = make_completion_items()
    self:__update({
      where = { id = 1 },
      set = { tag_strings = completion_items },
    })
  end
end

local M = {}

M.opts = {}

---Initialises the completion data functions
function M.init()
  init_tbl()
end

return M
