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
  PreviewKey = "@property",
  PreviewValue = "@variable",
  PreviewQuestion = "Title",
  PreviewAnswer = "@variable",
  ResultsAuthor = "Title",
  ResultsYear = "@string",
  ResultsTitle = "@variable",
  ResultsFiles = "@property",
  ResultsNotes = "@comment.warning",
  ResultsQuestion = "Title",
  ResultsTimeAdded = "@string",
  ResultsCommand = "@property",
  PopupAuthor = "Title",
  PopupYear = "@string",
  PopupTitle = "@variable",
}

---Sets up all the default highlight groups
function M.setup()
  for papis_hl, linked_hl in pairs(links) do
    vim.api.nvim_set_hl(0, "Papis" .. papis_hl, { link = linked_hl, default = true })
  end
end

return M
