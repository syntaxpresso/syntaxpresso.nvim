local command_runner = require("syntaxpresso.utils.command_runner")

local M = {}

---Get Java basic types based on basic type kind (legacy method for backward compatibility)
---@param java_executable string Path to the Java executable
---@param basic_type_kind string Type of basic types to retrieve (e.g., "all-types", "id-types", "types-with-length", etc.)
---@param callback function Callback function that receives array of BasicJavaType or nil
function M.get_java_basic_types(java_executable, basic_type_kind, callback)
	-- This legacy function is maintained for backward compatibility
	-- It doesn't use the response/error pattern, so we adapt it
	local cwd = vim.fn.getcwd()
	local args = {
		cwd = cwd,
		["basic-type-kind"] = basic_type_kind,
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

---Get Java basic types from current directory with specified basic type kind
---@param cwd string|nil The working directory path (defaults to current working directory)
---@param basic_type_kind string Type of basic types to retrieve (e.g., "all-types", "id-types", "types-with-length", "types-with-time-zone-storage", "types-with-temporal", "types-with-extra-other", "types-with-precision-and-scale")
---@param callback fun(response: table|nil, error: string|nil) Callback function
---@param options table|nil Optional settings
function M.get_java_basic_types_modern(cwd, basic_type_kind, callback, options)
	-- Set default values
	local actual_cwd = cwd or vim.fn.getcwd()

	-- Validate callback
	if not callback or type(callback) ~= "function" then
		error("Callback function is required")
	end

	-- Validate basic_type_kind
	local valid_kinds = {
		["all-types"] = true,
		["id-types"] = true,
		["types-with-length"] = true,
		["types-with-time-zone-storage"] = true,
		["types-with-temporal"] = true,
		["types-with-extra-other"] = true,
		["types-with-precision-and-scale"] = true,
	}
	if not basic_type_kind or not valid_kinds[basic_type_kind] then
		callback(
			nil,
			"Invalid basic type kind. Must be one of: 'all-types', 'id-types', 'types-with-length', 'types-with-time-zone-storage', 'types-with-temporal', 'types-with-extra-other', 'types-with-precision-and-scale'"
		)
		return
	end

	-- Build arguments
	local args = {
		cwd = actual_cwd,
		["basic-type-kind"] = basic_type_kind,
	}

	-- Execute command
	command_runner.execute("get-java-basic-types", args, callback, options)
end

---Simplified version that gets Java basic types from current directory
---@param basic_type_kind string Type of basic types to retrieve (e.g., "all-types", "id-types", "types-with-length", etc.)
---@param callback fun(response: table|nil, error: string|nil) Callback function
function M.get_java_basic_types_simple(basic_type_kind, callback)
	M.get_java_basic_types_modern(nil, basic_type_kind, callback, nil)
end

return M
