local M = {}

---Get the core executable path (now includes UI functionality with --features ui)
---@return string|nil
local function get_core_executable()
	-- Try installed location first
	local installer = require("syntaxpresso.installer")
	local installed_path = installer.get_executable_path()

	if vim.fn.executable(installed_path) == 1 then
		return installed_path
	end

	return nil
end

---Parse JSON response from captured stdout lines
---@param lines table List of output lines from command
---@return table|nil Parsed response or nil
local function parse_response(lines)
	if not lines or #lines == 0 then
		return nil
	end

	-- Search backwards for JSON (last line should be the JSON response)
	for i = #lines, 1, -1 do
		local line = lines[i]
		-- Try to parse as JSON (Response<T> always starts with {)
		if line:match("^%s*{") then
			local ok, result = pcall(vim.json.decode, line)
			if ok and result.succeed ~= nil then -- Looks like Response<T>
				return result
			end
		end
	end

	return nil
end

---Reload a specific buffer if it's open
---@param file_path string Path to file
local function reload_buffer(file_path)
	local bufnr = vim.fn.bufnr(file_path)
	if bufnr ~= -1 then
		vim.api.nvim_buf_call(bufnr, function()
			vim.cmd("checktime") -- Reload only this buffer
		end)
	end
end

---Open a file in the editor
---@param file_path string Path to file
local function open_file(file_path)
	if vim.fn.filereadable(file_path) == 1 then
		vim.cmd("edit " .. vim.fn.fnameescape(file_path))
	end
end

---Handle successful operation with structured response
---@param response table Parsed JSON response
---@param opts table Options passed to launch_ui
local function handle_success(response, opts)
	local data = response.data

	if not data then
		vim.notify("Operation completed successfully!", vim.log.levels.INFO)
		return
	end

	-- Handle different response types based on command
	local command = response.command

	if command == "create-java-file" or command == "create-jpa-entity" then
		-- FileResponse: { fileType, filePackageName, filePath }
		if data.filePath then
			reload_buffer(data.filePath)
			open_file(data.filePath)
			vim.notify("Created: " .. data.filePath, vim.log.levels.INFO)
		end
	elseif
		command == "create-entity-basic-field"
		or command == "create-entity-id-field"
		or command == "create-entity-enum-field"
	then
		-- CreateEntityFieldResponse: { entityFilePath, fieldName, fieldType }
		if data.entityFilePath then
			reload_buffer(data.entityFilePath)
			vim.notify(
				string.format("Created field '%s' of type '%s'", data.fieldName or "?", data.fieldType or "?"),
				vim.log.levels.INFO
			)
		end
	elseif command == "create-one-to-one-relationship" or command == "create-many-to-one-relationship" then
		-- CreateRelationshipResponse: { owningSideEntityPath, inverseSideEntityPath, ... }
		local files_updated = 0

		if data.owningSideEntityPath then
			reload_buffer(data.owningSideEntityPath)
			files_updated = files_updated + 1
		end

		if data.inverseSideEntityPath then
			reload_buffer(data.inverseSideEntityPath)
			files_updated = files_updated + 1
		end

		vim.notify(
			string.format("Relationship created (%d file%s updated)", files_updated, files_updated ~= 1 and "s" or ""),
			vim.log.levels.INFO
		)
	elseif command == "create-jpa-repository-manual" then
		-- FileResponse from manual ID creation
		if data.filePath then
			reload_buffer(data.filePath)
			open_file(data.filePath)
			vim.notify("JPA repository created successfully with manual ID!", vim.log.levels.INFO)
		end
	else
		-- Generic success
		vim.notify("Operation completed successfully!", vim.log.levels.INFO)
	end

	-- Call custom success callback if provided
	if opts.on_success then
		opts.on_success(response)
	end
end

---Handle error with structured response
---@param response table|nil Parsed JSON response (if available)
---@param exit_code number Process exit code
---@param opts table Options passed to launch_ui
local function handle_error(response, exit_code, opts)
	if response and response.errorReason then
		vim.notify("Error: " .. response.errorReason, vim.log.levels.ERROR)
	elseif exit_code ~= 1 then
		-- Exit code 1 is user cancellation, don't show error
		vim.notify("Operation failed (exit code: " .. exit_code .. ")", vim.log.levels.ERROR)
	end

	-- Call custom error callback if provided
	if opts.on_error then
		opts.on_error(exit_code, response)
	end
end

---Launch the Rust UI in a floating terminal window
---@param ui_command string The UI command/subcommand to run
---@param args table|nil Optional arguments to pass to the UI (key-value pairs)
---@param opts table|nil Optional settings: { on_success, on_error, width, height }
function M.launch_ui(ui_command, args, opts)
	opts = opts or {}

	-- Get core executable (UI is now integrated with --features ui)
	local core_path = get_core_executable()
	if not core_path then
		vim.notify("Syntaxpresso core not found. Please install it first.", vim.log.levels.ERROR)
		return
	end

	-- Build command arguments as a table (list) for proper argument passing
	-- Now using: syntaxpresso-core ui <subcommand> <args>
	local cmd_parts = { core_path, "ui" }

	-- Add subcommand if provided
	if ui_command and ui_command ~= "" then
		table.insert(cmd_parts, ui_command)
	end

	-- Add arguments
	if args then
		for key, value in pairs(args) do
			if value ~= nil and value ~= "" then
				if type(value) == "boolean" then
					if value then
						table.insert(cmd_parts, "--" .. key)
					end
				else
					-- Add argument and value as separate entries (no shell escaping needed)
					table.insert(cmd_parts, "--" .. key)
					table.insert(cmd_parts, tostring(value))
				end
			end
		end
	end

	-- Calculate window size
	local width = opts.width or 80
	local height = opts.height or 25

	-- Create buffer for terminal
	local buf = vim.api.nvim_create_buf(false, true)

	-- Capture stdout for JSON parsing
	local stdout_lines = {}

	-- Create floating window
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = math.floor((vim.o.lines - height) / 2),
		col = math.floor((vim.o.columns - width) / 2),
		style = "minimal",
		border = "rounded",
	})

	-- Disable line numbers and other visual distractions
	vim.wo[win].number = false
	vim.wo[win].relativenumber = false
	vim.wo[win].signcolumn = "no"

	-- Launch terminal with the UI command (using table for proper argument handling)
	---@diagnostic disable-next-line: deprecated
	local job_id = vim.fn.termopen(cmd_parts, {
		cwd = vim.fn.getcwd(),
		on_stdout = function(_, data)
			-- Capture stdout for JSON parsing
			if data then
				for _, line in ipairs(data) do
					if line ~= "" then
						table.insert(stdout_lines, line)
					end
				end
			end
		end,
		on_exit = function(_, exit_code)
			vim.schedule(function()
				-- Close window and buffer
				if vim.api.nvim_win_is_valid(win) then
					vim.api.nvim_win_close(win, true)
				end
				if vim.api.nvim_buf_is_valid(buf) then
					vim.api.nvim_buf_delete(buf, { force = true })
				end

				-- Parse JSON response from stdout
				local response = parse_response(stdout_lines)

				-- Handle result based on exit code and response
				if exit_code == 0 and response and response.succeed then
					handle_success(response, opts)
				elseif response then
					handle_error(response, exit_code, opts)
				else
					-- Fallback: no JSON response
					if exit_code == 0 then
						-- Success but no JSON (shouldn't happen with new code)
						vim.cmd("checktime") -- Reload all buffers as fallback
						vim.notify("Operation completed!", vim.log.levels.INFO)
					elseif exit_code ~= 1 then
						-- Error and no JSON (exit code 1 is cancellation)
						vim.notify("Operation failed (exit code: " .. exit_code .. ")", vim.log.levels.ERROR)
					end
				end
			end)
		end,
	})

	-- Add TermClose autocmd for reliable cleanup
	vim.api.nvim_create_autocmd("TermClose", {
		buffer = buf,
		once = true,
		callback = function()
			vim.schedule(function()
				if vim.api.nvim_win_is_valid(win) then
					vim.api.nvim_win_close(win, true)
				end
			end)
		end,
	})

	-- Enter terminal insert mode
	vim.cmd("startinsert")

	-- Setup Esc key mapping for terminal mode (double Esc to exit)
	-- Use vim.uv (modern) or vim.loop (legacy) for compatibility
	local uv = vim.uv or vim.loop
	local esc_timer = uv.new_timer()
	vim.keymap.set("t", "<Esc>", function()
		if esc_timer and esc_timer:is_active() then
			esc_timer:stop()
			vim.cmd("stopinsert")
		elseif esc_timer then
			esc_timer:start(200, 0, function() end)
			return "<Esc>"
		end
	end, { buffer = buf, expr = true, nowait = true })

	return job_id
end

---Launch the Create Java File UI
---@param opts table|nil Optional settings
function M.launch_create_java_file(opts)
	opts = opts or {}

	-- Get current working directory
	local cwd = vim.fn.getcwd()

	-- Launch UI with JavaFile subcommand, passing cwd
	M.launch_ui("create-java-file", {
		cwd = cwd,
	}, {
		width = opts.width or 80,
		height = opts.height or 20,
	})
end

---Launch the Create JPA Entity UI
---@param opts table|nil Optional settings
function M.launch_create_jpa_entity(opts)
	opts = opts or {}

	-- Get current working directory
	local cwd = vim.fn.getcwd()

	-- Launch UI with JpaEntity subcommand, passing cwd
	M.launch_ui("create-jpa-entity", {
		cwd = cwd,
	}, {
		width = opts.width or 80,
		height = opts.height or 20,
	})
end

---Launch the Create Entity Field UI
---@param opts table|nil Optional settings
function M.launch_create_entity_field(opts)
	opts = opts or {}

	-- Get current buffer content
	local bufnr = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local source_code = table.concat(lines, "\n")
	local file_path = vim.api.nvim_buf_get_name(bufnr)

	-- Check if current file is a JPA entity
	local is_jpa_entity = false
	for _, line in ipairs(lines) do
		if line:match("@Entity") then
			is_jpa_entity = true
			break
		end
	end

	if not is_jpa_entity then
		vim.notify("Current file is not a JPA Entity", vim.log.levels.WARN)
		return
	end

	-- Check if file is saved
	if file_path == "" then
		vim.notify("Please save the file before creating a field", vim.log.levels.WARN)
		return
	end

	-- Base64 encode the source code
	local b64 = vim.base64.encode(source_code)

	-- Get current working directory
	local cwd = vim.fn.getcwd()

	-- Launch UI with EntityField subcommand, passing all required arguments
	M.launch_ui("create-jpa-entity-basic-field", {
		cwd = cwd,
		["entity-file-b64-src"] = b64,
		["entity-file-path"] = file_path,
	}, {
		width = opts.width or 90,
		height = opts.height or 35,
	})
end

---Launch the Create Entity Relationship UI
---@param opts table|nil Optional settings
function M.launch_create_entity_relationship(opts)
	opts = opts or {}

	-- Get current buffer content
	local bufnr = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local source_code = table.concat(lines, "\n")
	local file_path = vim.api.nvim_buf_get_name(bufnr)

	-- Check if current file is a JPA entity
	local is_jpa_entity = false
	for _, line in ipairs(lines) do
		if line:match("@Entity") then
			is_jpa_entity = true
			break
		end
	end

	if not is_jpa_entity then
		vim.notify("Current file is not a JPA Entity", vim.log.levels.WARN)
		return
	end

	-- Check if file is saved
	if file_path == "" then
		vim.notify("Please save the file before creating a relationship", vim.log.levels.WARN)
		return
	end

	-- Base64 encode the source code
	local b64 = vim.base64.encode(source_code)

	-- Get current working directory
	local cwd = vim.fn.getcwd()

	-- Launch UI with EntityRelationship subcommand, passing all required arguments
	M.launch_ui("create-jpa-one-to-one-relationship", {
		cwd = cwd,
		["entity-file-b64-src"] = b64,
		["entity-file-path"] = file_path,
	}, {
		width = opts.width or 100,
		height = opts.height or 40,
	})
end

---Launch the Create JPA Repository UI for the current entity
---@param opts table|nil Optional settings
function M.launch_create_jpa_repository(opts)
	opts = opts or {}

	-- Get current buffer content
	local bufnr = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local source_code = table.concat(lines, "\n")
	local file_path = vim.api.nvim_buf_get_name(bufnr)

	-- Check if current file is a JPA entity
	local is_jpa_entity = false
	for _, line in ipairs(lines) do
		if line:match("@Entity") then
			is_jpa_entity = true
			break
		end
	end

	if not is_jpa_entity then
		vim.notify("Current file is not a JPA Entity", vim.log.levels.WARN)
		return
	end

	-- Check if file is saved
	if file_path == "" then
		vim.notify("Please save the file before creating a repository", vim.log.levels.WARN)
		return
	end

	-- Base64 encode the source code
	local b64 = vim.base64.encode(source_code)

	-- Get current working directory
	local cwd = vim.fn.getcwd()

	-- Launch UI with JpaRepository subcommand - pass entity file data
	M.launch_ui("create-jpa-repository", {
		cwd = cwd,
		["entity-file-b64-src"] = b64,
		["entity-file-path"] = file_path,
	}, {
		width = opts.width or 90,
		height = opts.height or 25,
	})
end

return M
