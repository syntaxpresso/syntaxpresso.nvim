local command_runner = require("syntaxpresso.utils.command_runner")

local M = {}

---Get Java basic types based on field type kind (legacy method for backward compatibility)
---@param java_executable string Path to the Java executable
---@param field_type_kind string Either "all" or "id"
---@param callback function Callback function that receives array of BasicJavaType or nil
function M.get_java_basic_types(java_executable, field_type_kind, callback)
	-- This legacy function is maintained for backward compatibility
	-- It doesn't use the response/error pattern, so we adapt it
	local cwd = vim.fn.getcwd()
	local args = {
		cwd = cwd,
		["field-type-kind"] = field_type_kind,
	}

	command_runner.execute("get-java-basic-types", args, function(response, error)
		if error then
			vim.notify("Error getting Java basic types: " .. error, vim.log.levels.ERROR)
			callback(nil)
			return
		end

		if response and response.data then
			callback(response.data)
		else
			vim.notify("Failed to get Java basic types", vim.log.levels.WARN)
			callback(nil)
		end
	end)
end

---Get Java basic types from current directory with specified field type kind
---@param cwd string|nil The working directory path (defaults to current working directory)
---@param field_type_kind string Either "all" or "id"
---@param callback fun(response: table|nil, error: string|nil) Callback function
---@param options table|nil Optional settings
function M.get_java_basic_types_modern(cwd, field_type_kind, callback, options)
	-- Set default values
	local actual_cwd = cwd or vim.fn.getcwd()

	-- Validate callback
	if not callback or type(callback) ~= "function" then
		error("Callback function is required")
	end

	-- Validate field_type_kind
	local valid_kinds = { all = true, id = true }
	if not field_type_kind or not valid_kinds[field_type_kind] then
		callback(nil, "Invalid field type kind. Must be either 'all' or 'id'")
		return
	end

	-- Build arguments
	local args = {
		cwd = actual_cwd,
		["field-type-kind"] = field_type_kind,
	}

	-- Execute command
	command_runner.execute("get-java-basic-types", args, callback, options)
end

---Simplified version that gets Java basic types from current directory
---@param field_type_kind string Either "all" or "id"
---@param callback fun(response: table|nil, error: string|nil) Callback function
function M.get_java_basic_types_simple(field_type_kind, callback)
	M.get_java_basic_types_modern(nil, field_type_kind, callback, nil)
end

return M
