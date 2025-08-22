local M = {}

---@class DataTransferObject
---@field succeed boolean
---@field data table|nil
---@field errorReason string|nil

---@class RenameResponse
---@field filePath string
---@field renamedNodes integer
---@field newName string

---@class GetTextResponse
---@field filePath string
---@field node string
---@field text string

---@class GetMainClassResponse
---@field filePath string
---@field packageName string

---@class CreateNewFileResponse
---@field filePath string

---@alias SyntaxpressoResponse DataTransferObject

---Parse Java executable response that may contain debug output before JSON
---@param raw_output string The raw output from the Java executable
---@return boolean success True if parsing succeeded
---@return DataTransferObject|string result The parsed JSON object or error message
function M.parse_response(raw_output)
  if not raw_output or raw_output == "" then
    return false, "Empty response"
  end

  local json_start = raw_output:find("{")
  if not json_start then
    return false, "No JSON found in response"
  end

  local json_str = raw_output:sub(json_start)
  return pcall(vim.json.decode, json_str)
end

return M
