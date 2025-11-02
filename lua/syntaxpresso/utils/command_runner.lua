local installer = require("syntaxpresso.installer")

local M = {}

-- Configuration
local config = {
	executable_path = nil,
	default_timeout = 30000, -- 30 seconds
}

---Setup command runner with configuration
---@param opts table|nil Configuration options
function M.setup(opts)
	config = vim.tbl_deep_extend("force", config, opts or {})
end

---Get the syntaxpresso executable path
---@return string
local function get_executable()
	if config.executable_path then
		return config.executable_path
	end
	return installer.get_executable_path()
end

---Convert table arguments to command line format
---@param tbl table Key-value pairs for arguments
---@return string[]
local function build_args_from_table(tbl)
	local parts = {}

	for key, value in pairs(tbl) do
		if value ~= nil then
			local arg_value = value

			-- Handle special encoding options
			if type(value) == "table" and value.value then
				arg_value = value.value
				if value.encode == "base64" then
					arg_value = vim.base64.encode(tostring(arg_value))
				elseif value.encode == "url" then
					-- Simple URL encoding for spaces and special chars
					arg_value = tostring(arg_value):gsub("([^%w%-%.%_%~])", function(c)
						return string.format("%%%02X", string.byte(c))
					end)
				end
			end

			-- Convert value to string
			local str_value = tostring(arg_value)

			-- Handle spaces and special characters by quoting
			if str_value:find("%s") or str_value:find("[\"'\\]") then
				str_value = '"' .. str_value:gsub('"', '\\"') .. '"'
			end

			table.insert(parts, "--" .. key .. "=" .. str_value)
		end
	end

	return parts
end

---Parse arguments into command parts array
---Supports both string and table formats for maximum flexibility
---@param args string|table|nil Arguments in string format or object format
---@return string[]
local function parse_args(args)
	if not args then
		return {}
	end

	-- Handle string arguments (backward compatibility)
	if type(args) == "string" then
		if args == "" then
			return {}
		end
		local parts = {}
		-- Split by spaces, but preserve quoted strings
		for arg in args:gmatch("%S+") do
			table.insert(parts, arg)
		end
		return parts
	end

	-- Handle table/object arguments (new feature)
	if type(args) == "table" then
		return build_args_from_table(args)
	end

	error("Arguments must be string or table, got: " .. type(args))
end

---Build complete command array for execution
---@param command string The syntaxpresso sub-command (e.g., "get-info", "rename")
---@param args string|table|nil Arguments in string format or object format
---@return string[]
local function build_command(command, args)
	local executable = get_executable()
	local cmd_parts = { executable, command }

	-- Add parsed arguments
	local arg_parts = parse_args(args)
	for _, arg in ipairs(arg_parts) do
		table.insert(cmd_parts, arg)
	end

	return cmd_parts
end

---Parse JSON response from command output
---@param raw_output string Raw command output
---@return table|nil response Parsed response object
---@return string|nil error Error message if parsing failed
local function parse_response(raw_output)
	if not raw_output or raw_output == "" then
		return nil, "Empty response from command"
	end

	-- Find JSON start (skip any debug output)
	local json_start = raw_output:find("{")
	if not json_start then
		return nil, "No JSON found in response: " .. raw_output
	end

	local json_str = raw_output:sub(json_start)
	local ok, result = pcall(vim.json.decode, json_str)

	if not ok then
		return nil, "Failed to parse JSON: " .. tostring(result)
	end

	return result, nil
end

---Execute command using vim.system (Neovim 0.10+)
---@param cmd_parts string[] Command parts array
---@param callback fun(response: table|nil, error: string|nil)
---@param timeout number|nil Timeout in milliseconds
local function execute_with_system(cmd_parts, callback, timeout)
	local actual_timeout = timeout or config.default_timeout

	vim.system(cmd_parts, { timeout = actual_timeout }, function(result)
		if result.code ~= 0 then
			local error_msg = "Command failed with exit code " .. result.code
			if result.stderr and result.stderr ~= "" then
				error_msg = error_msg .. ": " .. result.stderr
			end
			callback(nil, error_msg)
			return
		end

		if not result.stdout or result.stdout == "" then
			callback(nil, "No output received from command")
			return
		end

		local response, parse_error = parse_response(result.stdout)
		if parse_error then
			callback(nil, parse_error)
			return
		end

		-- Check if command succeeded according to response
		if not response or not response.succeed then
			local error_reason = response and response.errorReason or "Command failed without specific reason"
			callback(nil, error_reason)
			return
		end

		callback(response, nil)
	end)
end

---Execute command using vim.fn.jobstart (fallback for older Neovim)
---@param cmd_parts string[] Command parts array
---@param callback fun(response: table|nil, error: string|nil)
---@param timeout number|nil Timeout in milliseconds
local function execute_with_jobstart(cmd_parts, callback, timeout)
	local output = {}
	local error_output = {}
	local actual_timeout = timeout or config.default_timeout

	local job_id = vim.fn.jobstart(cmd_parts, {
		on_stdout = function(_, data)
			if data and #data > 0 then
				for _, line in ipairs(data) do
					if line ~= "" then
						table.insert(output, line)
					end
				end
			end
		end,

		on_stderr = function(_, data)
			if data and #data > 0 then
				for _, line in ipairs(data) do
					if line ~= "" then
						table.insert(error_output, line)
					end
				end
			end
		end,

		on_exit = function(_, exit_code)
			if exit_code ~= 0 then
				local error_msg = "Command failed with exit code " .. exit_code
				if #error_output > 0 then
					error_msg = error_msg .. ": " .. table.concat(error_output, "\n")
				end
				callback(nil, error_msg)
				return
			end

			local raw_output = table.concat(output, "")
			if raw_output == "" then
				callback(nil, "No output received from command")
				return
			end

			local response, parse_error = parse_response(raw_output)
			if parse_error then
				callback(nil, parse_error)
				return
			end

			-- Check if command succeeded according to response
			if not response or not response.succeed then
				local error_reason = response and response.errorReason or "Command failed without specific reason"
				callback(nil, error_reason)
				return
			end

			callback(response, nil)
		end,
	})

	if job_id <= 0 then
		callback(nil, "Failed to start command")
		return
	end

	-- Set up timeout
	vim.defer_fn(function()
		if vim.fn.jobstop(job_id) == 1 then
			callback(nil, "Command timed out after " .. actual_timeout .. "ms")
		end
	end, actual_timeout)
end

---Execute a syntaxpresso command with flexible argument support
---@param command string The syntaxpresso sub-command (e.g., "get-info", "rename", "create-new-jpa-entity")
---@param args string|table|nil Arguments in string format (e.g., "--line=10 --column=5") or object format (e.g., {line=10, column=5})
---@param callback fun(response: table|nil, error: string|nil) Callback function that receives response or error
---@param options table|nil Optional settings: { timeout }
function M.execute(command, args, callback, options)
	-- Validate inputs
	if not command or command == "" then
		callback(nil, "Command name is required")
		return
	end

	if not callback or type(callback) ~= "function" then
		error("Callback function is required")
		return
	end

	-- Parse options
	local opts = options or {}
	local timeout = opts.timeout

	-- Build command
	local cmd_parts = build_command(command, args)

	-- Execute command (prefer vim.system if available)
	if vim.system then
		execute_with_system(cmd_parts, callback, timeout)
	else
		execute_with_jobstart(cmd_parts, callback, timeout)
	end
end

---Simplified execute function with default error handling
---@param command string The syntaxpresso sub-command
---@param args string|table|nil Arguments in string or object format
---@param success_callback fun(response: table) Success callback
---@param error_callback fun(error: string)|nil Optional error callback
function M.run(command, args, success_callback, error_callback)
	M.execute(command, args, function(response, error)
		if error then
			if error_callback then
				error_callback(error)
			else
				vim.notify("Command error: " .. error, vim.log.levels.ERROR)
			end
		elseif response then
			success_callback(response)
		end
	end)
end

return M
