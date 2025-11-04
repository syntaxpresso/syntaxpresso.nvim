local command_runner = require("syntaxpresso.utils.command_runner")

local M = {}

---Get all superclasses from the current working directory
---@param cwd string|nil The working directory path (defaults to current working directory)
---@param callback fun(response: table|nil, error: string|nil) Callback function
---@param options table|nil Optional settings
function M.get_all_superclasses(cwd, callback, options)
	-- Set default value
	local actual_cwd = cwd or vim.fn.getcwd()
	-- Validate callback
	if not callback or type(callback) ~= "function" then
		error("Callback function is required")
	end
	-- Build arguments
	local args = {
		cwd = actual_cwd,
	}
	-- Execute command
	command_runner.execute("get-all-superclasses", args, callback, options)
end

---Simplified version that gets all superclasses from current directory
---@param callback fun(response: table|nil, error: string|nil) Callback function
function M.get_all_superclasses_simple(callback)
	M.get_all_superclasses(nil, callback, nil)
end

return M
