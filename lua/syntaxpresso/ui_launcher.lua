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

	-- Fallback: try development path
	local dev_path = vim.fn.expand("~/Documents/projects/syntaxpresso/core/target/release/syntaxpresso-core")
	if vim.fn.executable(dev_path) == 1 then
		return dev_path
	end

	return nil
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
		on_exit = function(_, exit_code)
			vim.schedule(function()
				-- Close window and buffer
				if vim.api.nvim_win_is_valid(win) then
					vim.api.nvim_win_close(win, true)
				end
				if vim.api.nvim_buf_is_valid(buf) then
					vim.api.nvim_buf_delete(buf, { force = true })
				end

				-- Handle exit code
				if exit_code == 0 then
					-- Success! Reload buffer to show changes
					vim.cmd("checktime")
					if opts.on_success then
						opts.on_success()
					else
						vim.notify("Operation completed successfully!", vim.log.levels.INFO)
					end
				elseif exit_code ~= 0 and opts.on_error then
					opts.on_error(exit_code)
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
	M.launch_ui("java-file", {
		cwd = cwd,
	}, {
		width = opts.width or 80,
		height = opts.height or 20,
		on_success = function()
			vim.notify("Java file created successfully!", vim.log.levels.INFO)
		end,
		on_error = function(code)
			if code ~= 1 then -- Exit code 1 is just user cancellation
				vim.notify("Failed to create Java file (exit code: " .. code .. ")", vim.log.levels.ERROR)
			end
		end,
	})
end

---Launch the Create JPA Entity UI
---@param opts table|nil Optional settings
function M.launch_create_jpa_entity(opts)
	opts = opts or {}

	-- Get current working directory
	local cwd = vim.fn.getcwd()

	-- Launch UI with JpaEntity subcommand, passing cwd
	M.launch_ui("jpa-entity", {
		cwd = cwd,
	}, {
		width = opts.width or 80,
		height = opts.height or 20,
		on_success = function()
			vim.notify("JPA Entity created successfully!", vim.log.levels.INFO)
		end,
		on_error = function(code)
			if code ~= 1 then -- Exit code 1 is just user cancellation
				vim.notify("Failed to create JPA Entity (exit code: " .. code .. ")", vim.log.levels.ERROR)
			end
		end,
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
	M.launch_ui("entity-field", {
		cwd = cwd,
		["entity-file-b64-src"] = b64,
		["entity-file-path"] = file_path,
	}, {
		width = opts.width or 90,
		height = opts.height or 35,
		on_success = function()
			vim.notify("Entity field created successfully!", vim.log.levels.INFO)
		end,
		on_error = function(code)
			if code ~= 1 then
				vim.notify("Failed to create entity field (exit code: " .. code .. ")", vim.log.levels.ERROR)
			end
		end,
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
	M.launch_ui("entity-relationship", {
		cwd = cwd,
		["entity-file-b64-src"] = b64,
		["entity-file-path"] = file_path,
	}, {
		width = opts.width or 100,
		height = opts.height or 40,
		on_success = function()
			vim.notify("Entity relationship created successfully!", vim.log.levels.INFO)
		end,
		on_error = function(code)
			if code ~= 1 then
				vim.notify("Failed to create entity relationship (exit code: " .. code .. ")", vim.log.levels.ERROR)
			end
		end,
	})
end

return M
