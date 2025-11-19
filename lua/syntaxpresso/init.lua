local installer = require("syntaxpresso.installer")
local ui_launcher = require("syntaxpresso.ui_launcher")

local M = {}

-- Store custom executable path (accessible by other modules)
M.custom_executable_path = nil

--- Show a menu of available Syntaxpresso operations
function M.show_menu()
	-- Check if current file is a JPA entity
	local bufnr = vim.api.nvim_get_current_buf()
	local is_jpa_entity = false
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	for _, line in ipairs(lines) do
		if line:match("@Entity") then
			is_jpa_entity = true
			break
		end
	end

	-- Build menu options
	local options = {
		"Create Java file",
		"Create JPA Entity",
	}

	-- Add entity-specific options if in an entity file
	if is_jpa_entity then
		table.insert(options, "Create JPA Entity field")
		table.insert(options, "Create JPA Entity relationship")
		table.insert(options, "Create JPA Repository")
	end

	-- Show selection menu
	vim.ui.select(options, {
		prompt = "Syntaxpresso:",
	}, function(choice)
		if not choice then
			return
		end

		-- Execute the selected action
		if choice == "Create Java file" then
			ui_launcher.launch_create_java_file()
		elseif choice == "Create JPA Entity" then
			ui_launcher.launch_create_jpa_entity()
		elseif choice == "Create JPA Entity field" then
			ui_launcher.launch_create_entity_field()
		elseif choice == "Create JPA Entity relationship" then
			ui_launcher.launch_create_entity_relationship()
		elseif choice == "Create JPA Repository" then
			ui_launcher.launch_create_jpa_repository()
		end
	end)
end

function M.setup(opts)
	opts = opts or {}

	-- Store custom executable path at module level
	if opts.executable_path then
		M.custom_executable_path = opts.executable_path
	end

	local executable_path
	if opts.executable_path then
		executable_path = opts.executable_path
	else
		executable_path = installer.get_executable_path()
	end

	-- Check if the executable binary already exists.
	if
		vim.fn.isdirectory(installer.get_install_dir()) == 0
		or not (vim.fn.executable(executable_path) == 1 or vim.fn.filereadable(executable_path))
	then
		-- If custom executable_path is not provided and binary doesn't exist
		-- If it doesn't exist, create a command to prompt the user to install it.
		installer.install(function(path)
			if path then
				vim.notify("Installation successful!", vim.log.levels.INFO)
			else
				vim.notify("Installation failed. Please try again or check the logs.", vim.log.levels.ERROR)
			end
		end)
	end

	-- Create main menu command
	vim.api.nvim_create_user_command("Syntaxpresso", function()
		M.show_menu()
	end, {
		desc = "Show Syntaxpresso menu",
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
		ui_launcher.launch_create_jpa_repository()
	end, {
		desc = "Create a JPA Repository for current entity",
	})

	-- Set up keybinding if specified
	if opts.keymap ~= false then
		local keymap = opts.keymap or "<leader>cj"
		vim.keymap.set("n", keymap, function()
			M.show_menu()
		end, { desc = "Show Syntaxpresso menu", noremap = true, silent = true })
	end
end

return M
