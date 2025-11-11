local command_runner = require("syntaxpresso.utils.command_runner")

local M = {}

---Get JPA entity information from a file or source code
---@param cwd string|nil The working directory path (defaults to current working directory)
---@param entity_file_path string|nil Path to the entity file
---@param b64_source_code string|nil Base64 encoded source code
---@param callback fun(response: table|nil, error: string|nil) Callback function
---@param options table|nil Optional settings
function M.get_jpa_entity_info(cwd, entity_file_path, b64_source_code, callback, options)
	-- Set default values
	local actual_cwd = cwd or vim.fn.getcwd()
	
	-- Validate callback
	if not callback or type(callback) ~= "function" then
		error("Callback function is required")
	end
	
	-- Validate that at least one of entity_file_path or b64_source_code is provided
	if not entity_file_path and not b64_source_code then
		callback(nil, "Either entity_file_path or b64_source_code must be provided")
		return
	end
	
	-- Build arguments
	local args = {
		cwd = actual_cwd,
	}
	
	if entity_file_path then
		args["entity-file-path"] = entity_file_path
	end
	
	if b64_source_code then
		args["b64-source-code"] = b64_source_code
	end
	
	-- Execute command
	command_runner.execute("get-jpa-entity-info", args, callback, options)
end

---Get JPA entity info from a file path with current directory
---@param entity_file_path string Path to the entity file
---@param callback fun(response: table|nil, error: string|nil) Callback function
function M.get_jpa_entity_info_from_file(entity_file_path, callback)
	M.get_jpa_entity_info(nil, entity_file_path, nil, callback, nil)
end

---Get JPA entity info from base64 encoded source code with current directory
---@param b64_source_code string Base64 encoded source code
---@param callback fun(response: table|nil, error: string|nil) Callback function
function M.get_jpa_entity_info_from_source(b64_source_code, callback)
	M.get_jpa_entity_info(nil, nil, b64_source_code, callback, nil)
end

---Get JPA entity info from current buffer
---@param callback fun(response: table|nil, error: string|nil) Callback function
function M.get_jpa_entity_info_from_buffer(callback)
	-- Get current buffer content
	local bufnr = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local source_code = table.concat(lines, "\n")
	
	-- Encode to base64
	local b64_source_code = vim.base64.encode(source_code)
	
	M.get_jpa_entity_info(nil, nil, b64_source_code, callback, nil)
end

return M
