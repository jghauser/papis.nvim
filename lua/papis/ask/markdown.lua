--
-- PAPIS | ASK | MARKDOWN
--
--
-- Utilities for formatting ask answers as markdown
--

local db = assert(require("papis.sqlite-wrapper"), "Failed to load papis.sqlite-wrapper")

---Convert LaTeX math notation to standard markdown
---@param text string Text containing LaTeX math
---@return string Text with converted math notation
local function to_latex_math(text)
  local result = text:gsub("\\%(", "$")
  result = result:gsub("\\%)", "$")
  result = result:gsub("\\%[", "$$")
  result = result:gsub("\\%]", "$$")
  return result
end

---Convert papis_id to ref
---@param papis_id string The papis_id to convert
---@return string ref The corresponding ref (or papis_id if not found)
local function papis_id_to_ref(papis_id)
  local ref = db.data:get_value({ papis_id = papis_id }, "ref") or papis_id
  return ref
end

---@class PapisAskModule
local M = {}

---Transform answer by converting math notation and formatting references
---@param answer string The answer
---@return string transformed_answer Transformed answer
function M.transform_answer(answer)
  local transformed_answer = to_latex_math(answer)

  -- Pattern: (papis_id pages X-N) -> [@ref, X-N]
  local function replace_citation(papis_id, pages)
    local ref = papis_id_to_ref(papis_id)
    if pages then
      return string.format("[@%s, %s]", ref, pages)
    else
      return string.format("[@%s]", ref)
    end
  end

  -- Replace citations with pages
  transformed_answer = transformed_answer:gsub("%((%w+)%s+pages%s+([^)]+)%)", replace_citation)
  -- Replace citations without pages
  transformed_answer = transformed_answer:gsub("%((%w+)%)", function(papis_id)
    return replace_citation(papis_id, nil)
  end)

  return transformed_answer
end

---Format the answer as a well-formatted markdown document
---@param entry PapisAskEntry The ask entry
---@return string markdown_string Formatted markdown
function M:to_markdown_output(entry)
  local transformed_answer = self.transform_answer(entry.answer)
  local markdown = {}

  table.insert(markdown, "# Question\n")
  table.insert(markdown, entry.question .. "\n")

  table.insert(markdown, "# Answer\n")
  local answer_text = transformed_answer
  local lines = vim.split(answer_text, "\n")
  -- Determine if we need to adjust heading levels
  local min_heading_level = math.huge
  for _, line in ipairs(lines) do
    if line:match("^#+%s") then
      local level = 0
      for char in line:gmatch(".") do
        if char == "#" then
          level = level + 1
        else
          break
        end
      end
      min_heading_level = math.min(min_heading_level, level)
    end
  end
  -- If the minimum heading level is 1, shift all headings
  if min_heading_level == 1 then
    local adjusted_lines = {}
    for _, line in ipairs(lines) do
      if line:match("^#+%s") then
        table.insert(adjusted_lines, "#" .. line)
      else
        table.insert(adjusted_lines, line)
      end
    end
    answer_text = table.concat(adjusted_lines, "\n")
  end
  table.insert(markdown, answer_text .. "\n")

  table.insert(markdown, "## References\n")
  for _, context in ipairs(entry.contexts or {}) do
    local ref = papis_id_to_ref(context.papis_id)
    local pages = context.pages or ""
    if pages ~= "" then
      table.insert(markdown, string.format("- @%s, %s", ref, pages))
    else
      table.insert(markdown, string.format("- @%s", ref))
    end
  end

  table.insert(markdown, "\n# Context\n")
  for _, context in ipairs(entry.contexts or {}) do
    local ref = papis_id_to_ref(context.papis_id)
    local pages = context.pages or ""
    if pages ~= "" then
      table.insert(markdown, string.format("## @%s, %s\n", ref, pages))
    else
      table.insert(markdown, string.format("## @%s\n", ref))
    end
    table.insert(markdown, (context.summary or context.context or "") .. "\n")
    if context.score then
      table.insert(markdown, string.format("**Score:** %s\n", context.score))
    end
  end

  local markdown_string = table.concat(markdown, "\n")
  return markdown_string
end

return M
