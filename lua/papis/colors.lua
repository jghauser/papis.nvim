--
-- PAPIS | COLORS
--
--
-- Adapted from https://github.com/folke/trouble.nvim
--

local M = {}

local links = {
  PreviewAuthor = "Title",
  PreviewYear = "@string",
  PreviewTitle = "@variable",
  PreviewKey = "@string",
  PreviewValue = "@variable",
  PopupAuthor = "Title",
  PopupYear = "@string",
  PopupTitle = "@variable",
  ResultsAuthor = "@tag",
  ResultsYear = "@string",
  ResultsTitle = "@variable",
}

---Sets up all the default highlight groups
function M.setup()
  for papis_hl, linked_hl in pairs(links) do
    vim.api.nvim_set_hl(0, "Papis" .. papis_hl, { link = linked_hl, default = true })
  end
end

return M
