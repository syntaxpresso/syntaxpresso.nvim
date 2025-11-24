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

	-- Default auto-update settings (enabled by default, silent install)
	opts.auto_update = vim.tbl_deep_extend("force", {
		enabled = true, -- Auto-update ON by default
		frequency = "always", -- Check on every Neovim start
		prompt = false, -- Silent install (no prompts)
	}, opts.auto_update or {})

	-- Store custom executable path at module level
	if opts.executable_path then
		M.custom_executable_path = opts.executable_path
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

	-- Enhanced user command for updating core binary
	vim.api.nvim_create_user_command("SyntaxpressoUpdateCore", function()
		local installer = require("syntaxpresso.installer")
		local version_checker = require("syntaxpresso.version_checker")

		vim.notify("Checking for updates...", vim.log.levels.INFO)

		version_checker.get_local_version(function(local_version)
			installer.install(function(path)
				if path then
					version_checker.get_local_version(function(new_version)
						if new_version and new_version ~= local_version then
							vim.notify(
								string.format("✓ Updated: v%s → v%s", local_version or "none", new_version),
								vim.log.levels.INFO
							)
						else
							vim.notify("✓ Already up to date", vim.log.levels.INFO)
						end
					end)
				else
					vim.notify("✗ Update failed", vim.log.levels.ERROR)
				end
			end)
		end)
	end, {
		desc = "Update Syntaxpresso core binary to latest version",
	})

	-- Set up keybinding if specified
	if opts.keymap ~= false then
		local keymap = opts.keymap or "<leader>cj"
		vim.keymap.set("n", keymap, function()
			M.show_menu()
		end, { desc = "Show Syntaxpresso menu", noremap = true, silent = true })
	end

	-- Check for updates on startup (deferred to not block)
	local version_checker = require("syntaxpresso.version_checker")
	vim.defer_fn(function()
		version_checker.check_and_prompt_update(opts)
	end, 1000) -- Wait 1 second after startup
end

return M
