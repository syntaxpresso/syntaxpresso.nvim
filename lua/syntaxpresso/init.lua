local installer = require("syntaxpresso.installer")
local ui_launcher = require("syntaxpresso.ui_launcher")

local M = {}

-- Track if setup has already been called
local setup_called = false

-- Store custom executable path (accessible by other modules)
M.custom_executable_path = nil

function M.setup(opts)
	opts = opts or {}

	-- Store custom executable path at module level
	if opts.executable_path then
		M.custom_executable_path = opts.executable_path
	end

	local get_executable = function()
		if opts.executable_path then
			return opts.executable_path
		else
			return installer.get_executable_path()
		end
	end

	require("null-ls").register({
		name = "syntaxpresso-actions",
		method = { require("null-ls").methods.CODE_ACTION },
		filetypes = { "java" },
		generator = {
			fn = function(params)
				local executable = get_executable()
				if vim.fn.filereadable(executable) ~= 1 then
					return {}
				end

				local actions = {
					{
						title = "Create Java file",
						action = function()
							-- Use Rust UI
							ui_launcher.launch_create_java_file()
						end,
					},
					{
						title = "Create JPA Entity",
						action = function()
							-- Use Rust UI
							ui_launcher.launch_create_jpa_entity()
						end,
					},
				}

				-- Check if current file is a JPA entity
				-- We need to do this synchronously to decide which actions to show
				local bufnr = params.bufnr or vim.api.nvim_get_current_buf()
				local is_jpa_entity = false

				-- Quick check: if buffer has @Entity annotation, it's likely a JPA entity
				local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
				for _, line in ipairs(lines) do
					if line:match("@Entity") then
						is_jpa_entity = true
						break
					end
				end

				-- Only add field and relationship actions if it's a JPA entity
				if is_jpa_entity then
					table.insert(actions, {
						title = "Create JPA Entity field",
						action = function()
							-- Use Rust UI
							ui_launcher.launch_create_entity_field()
						end,
					})

					table.insert(actions, {
						title = "Create JPA Entity relationship",
						action = function()
							-- Use Rust UI
							ui_launcher.launch_create_entity_relationship()
						end,
					})

					table.insert(actions, {
						title = "Create JPA Repository",
						action = function()
							-- Use Rust UI (TUI with ID type selector)
							ui_launcher.launch_create_jpa_repository()
						end,
					})
				end

				return actions
			end,
		},
	})

	if setup_called and not opts.executable_path then
		vim.notify("Setup already called, skipping", vim.log.levels.WARN)
		return
	end
	setup_called = true

	local executable_path
	if opts.executable_path then
		executable_path = opts.executable_path
		vim.notify("Using custom executable: " .. executable_path, vim.log.levels.INFO)
	else
		executable_path = installer.get_executable_path()
	end

	-- Check if the executable binary already exists.
	if not (vim.fn.executable(executable_path) == 1 or vim.fn.filereadable(executable_path)) then
		-- If custom executable_path is not provided and binary doesn't exist
		-- If it doesn't exist, create a command to prompt the user to install it.
		vim.api.nvim_create_user_command("SyntaxpressoInstall", function()
			vim.notify("Installing syntaxpresso core...", vim.log.levels.INFO)

			-- The installer function is called with a callback.
			installer.install(function(path)
				if path then
					vim.notify("Installation successful! Restart Neovim to load code actions.", vim.log.levels.INFO)
					-- Remove the installation command as it's no longer needed for this session.
					pcall(vim.api.nvim_del_user_command, "SyntaxpressoInstall")
				end
			end)
		end, {
			desc = "Downloads and installs the syntaxpresso core binary.",
		})

		vim.notify("Syntaxpresso: core not found. Run :SyntaxpressoInstall", vim.log.levels.WARN)
	end

	-- Also, create a command to allow users to update the binary.
	vim.api.nvim_create_user_command("SyntaxpressoUpdate", function()
		vim.notify("Checking for syntaxpresso updates...", vim.log.levels.INFO)
		installer.install(function(path)
			if path then
				vim.notify("Update successful! Please restart Neovim to apply changes.", vim.log.levels.INFO)
			else
				vim.notify("Update failed or you are already on the latest version.", vim.log.levels.ERROR)
			end
		end)
	end, {
		desc = "Checks for and installs updates to the syntaxpresso core binary.",
	})

	-- Create user command for creating Java files using Rust UI
	vim.api.nvim_create_user_command("SyntaxpressoCreateJavaFile", function()
		ui_launcher.launch_create_java_file()
	end, {
		desc = "Create a new Java file using Rust UI",
	})

	-- Create user command for creating JPA entities using Rust UI
	vim.api.nvim_create_user_command("SyntaxpressoCreateJpaEntity", function()
		ui_launcher.launch_create_jpa_entity()
	end, {
		desc = "Create a new JPA Entity using Rust UI",
	})

	-- Create user command for creating entity fields using Rust UI
	vim.api.nvim_create_user_command("SyntaxpressoCreateEntityField", function()
		ui_launcher.launch_create_entity_field()
	end, {
		desc = "Create a new JPA Entity field using Rust UI",
	})

	-- Create user command for creating entity relationships using Rust UI
	vim.api.nvim_create_user_command("SyntaxpressoCreateEntityRelationship", function()
		ui_launcher.launch_create_entity_relationship()
	end, {
		desc = "Create a new JPA Entity relationship using Rust UI",
	})

	-- Create user command for creating JPA repositories
	vim.api.nvim_create_user_command("SyntaxpressoCreateJpaRepository", function()
		require("syntaxpresso.commands.create_jpa_repository").execute_create_jpa_repository(executable_path)
	end, {
		desc = "Create a JPA Repository for the current entity with automatic ID field resolution",
	})

	-- Create user command for creating JPA repositories with TUI
	vim.api.nvim_create_user_command("SyntaxpressoCreateJpaRepositoryTui", function()
		ui_launcher.launch_create_jpa_repository()
	end, {
		desc = "Create a JPA Repository for current entity (TUI with ID type selector)",
	})
end

return M
