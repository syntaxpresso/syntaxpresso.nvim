local command_runner = require("syntaxpresso.utils.command_runner")

local M = {}

---Get all packages from the current working directory
---@param cwd string|nil The working directory path (defaults to current working directory)
---@param source_directory string|nil The source directory type ("main" or "test", defaults to "main")
---@param callback fun(response: table|nil, error: string|nil) Callback function
---@param options table|nil Optional settings
function M.get_all_packages(cwd, source_directory, callback, options)
	-- Set default values
	local actual_cwd = cwd or vim.fn.getcwd()
	local actual_source_directory = source_directory or "main"
	-- Validate callback
	if not callback or type(callback) ~= "function" then
		error("Callback function is required")
	end
	-- Build arguments
	local args = {
		cwd = actual_cwd,
		["source-directory"] = actual_source_directory,
	}
	-- Execute command
	command_runner.execute("get-all-packages", args, callback, options)
end

---Simplified version that gets all packages from current directory with default options
---@param callback fun(response: table|nil, error: string|nil) Callback function
function M.get_all_packages_simple(callback)
	M.get_all_packages(nil, nil, callback, nil)
end

return M
