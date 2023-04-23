--
-- PAPIS | COLORS
--
--
-- Adapted from https://github.com/folke/trouble.nvim
--

local M = {}

local links = {
  PreviewAuthor = "Title",
  PreviewYear = "Statement",
  PreviewTitle = "Normal",
  PreviewKey = "Conditional",
  PreviewValue = "Normal",
  PopupAuthor = "Title",
  PopupYear = "Statement",
  PopupTitle = "Normal",
  ResultsAuthor = "PreProc",
  ResultsYear = "Statement",
  ResultsTitle = "TelescopeResultsNormal",
}

---Sets up all the default highlight groups
function M.setup()
  for papis_hl, linked_hl in pairs(links) do
    vim.api.nvim_set_hl(0, "Papis" .. papis_hl, { link = linked_hl, default = true })
  end
end

return M
