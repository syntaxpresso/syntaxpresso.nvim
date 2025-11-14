local command_runner = require("syntaxpresso.utils.command_runner")

local M = {}

---Get Java files from the current working directory filtered by file type
---@param cwd string|nil The working directory path (defaults to current working directory)
---@param file_type string The Java file type: "class", "enum", "interface", "record", or "annotation"
---@param callback fun(response: table|nil, error: string|nil) Callback function
---@param options table|nil Optional settings
function M.get_java_files(cwd, file_type, callback, options)
	-- Set default values
	local actual_cwd = cwd or vim.fn.getcwd()

	-- Validate callback
	if not callback or type(callback) ~= "function" then
		error("Callback function is required")
	end

	-- Validate file_type
	local valid_types = { class = true, enum = true, interface = true, record = true, annotation = true }
	if not file_type or not valid_types[file_type] then
		callback(nil, "Invalid file type. Must be one of: class, enum, interface, record, annotation")
		return
	end

	-- Build arguments
	local args = {
		cwd = actual_cwd,
		["file-type"] = file_type,
	}

	-- Execute command
	command_runner.execute("get-java-files", args, callback, options)
end

---Simplified version that gets Java files from current directory with specified type
---@param file_type string The Java file type: "class", "enum", "interface", "record", or "annotation"
---@param callback fun(response: table|nil, error: string|nil) Callback function
function M.get_java_files_simple(file_type, callback)
	M.get_java_files(nil, file_type, callback, nil)
end

return M
