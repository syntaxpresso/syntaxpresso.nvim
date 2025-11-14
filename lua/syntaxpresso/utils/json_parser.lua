local M = {}

---@class Response
---@field command string
---@field cwd string
---@field succeed boolean
---@field data table|nil
---@field errorReason string|nil

---@class FileResponse
---@field fileType string
---@field filePackageName string
---@field filePath string

---@class ErrorResponse
---@field error string
---@field message string

---@class CreateJPARepositoryResponse
---@field idFieldFound boolean
---@field superclassType string|nil
---@field repository FileResponse|nil

---@class GetJpaEntityInfoResponse
---@field isJpaEntity boolean
---@field entityType string
---@field entityPackageName string
---@field superclassType string|nil
---@field entityPath string|nil
---@field idFieldType string|nil
---@field idFieldPackageName string|nil

---@class GetFilesResponse
---@field files FileResponse[]
---@field filesCount integer

---@class PackageResponse
---@field packageName string

---@class BasicJavaType
---@field id string
---@field name string
---@field packagePath string|nil

---@class CreateNewFileResponse
---@field filePath string

---@class CreateJPAOneToOneRelationshipResponse
---@field success boolean
---@field message string
---@field owningSideEntityUpdated boolean
---@field inverseSideEntityUpdated boolean
---@field owningSideEntityPath string|nil
---@field inverseSideEntityPath string|nil

---@alias SyntaxpressoResponse Response

---Parse Java executable response that may contain debug output before JSON
---@param raw_output string The raw output from the Java executable
---@return boolean success True if parsing succeeded
---@return Response|string result The parsed JSON object or error message
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
