-- lua/syntaxpresso/init.lua

local installer = require("syntaxpresso.installer")
local create_jpa_entity = require("syntaxpresso.ui.create_jpa_entity")
local create_java_file = require("syntaxpresso.ui.create_java_file")
local command_runner = require("syntaxpresso.utils.command_runner")
local get_all_packages = require("syntaxpresso.commands.get_all_packages")
local get_java_files = require("syntaxpresso.commands.get_java_files")
local get_java_basic_types = require("syntaxpresso.commands.get_java_basic_types")
local get_all_superclasses = require("syntaxpresso.commands.get_all_superclasses")

local M = {}

-- Track if setup has already been called
local setup_called = false

function M.setup(opts)
	opts = opts or {}

	-- Setup command runner with the same configuration
	command_runner.setup(opts)

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
			fn = function()
				local executable = get_executable()
				if vim.fn.filereadable(executable) ~= 1 then
					return {}
				end
				return {
					{
						title = "Create Java file",
						action = function()
							get_all_packages.get_all_packages_simple(function(response, error)
								if error then
									vim.notify("Failed to get packages: " .. error, vim.log.levels.WARN)
									return
								end
								local results = {
									packages = response,
								}
								vim.schedule(function()
									create_java_file.render_create_java_file_ui(results)
								end)
							end)
						end,
					},
					{
						title = "Create JPA Entity",
						action = function()
							local results = {
								packages = nil,
								superclasses = nil,
							}
							local completed = 0
							local total = 2
							local has_error = false
							local function check_and_render()
								completed = completed + 1
								if completed == total and not has_error then
									if results.packages and results.superclasses then
										vim.schedule(function()
											create_jpa_entity.render_create_jpa_entity_ui({
												packages = results.packages,
												superclasses = results.superclasses,
											})
										end)
									end
								end
							end
							get_all_packages.get_all_packages_simple(function(response, error)
								if error then
									has_error = true
									vim.notify("Failed to get packages: " .. error, vim.log.levels.WARN)
									return
								end
								results.packages = response
								check_and_render()
							end)
							get_all_superclasses.get_all_superclasses_simple(function(response, error)
								if error then
									has_error = true
									vim.notify("Failed to get superclasses: " .. error, vim.log.levels.WARN)
									return
								end
								results.superclasses = response
								check_and_render()
							end)
						end,
					},
					{
						title = "Create JPA Entity field",
						action = function()
							local exec = get_executable()
							local results = {
								basic_types = nil,
								id_types = nil,
								enum_files = nil,
							}
							local completed = 0
							local total = 3
							local has_error = false
							local function check_and_render()
								completed = completed + 1
								if completed == total and not has_error then
									if results.basic_types and results.id_types and results.enum_files then
										vim.schedule(function()
											create_jpa_entity.render_create_jpa_entity_ui({
												basic_types = results.basic_types,
												id_types = results.id_types,
												enum_files = results.enum_files,
											})
										end)
									end
								end
							end
							get_java_basic_types.get_java_basic_types(exec, "all", function(response)
								if not response then
									has_error = true
									vim.notify("Failed to get basic types", vim.log.levels.WARN)
									return
								end
								results.basic_types = response
								check_and_render()
							end)
							get_java_basic_types.get_java_basic_types(exec, "id", function(response)
								if not response then
									has_error = true
									vim.notify("Failed to get id types", vim.log.levels.WARN)
									return
								end
								results.id_types = response
								check_and_render()
							end)
							get_java_files.get_java_files_simple("enum", function(response, error)
								if error then
									has_error = true
									vim.notify("Failed to get enum files: " .. error, vim.log.levels.WARN)
									return
								end
								results.enum_files = response
								check_and_render()
							end)
						end,
					},
				}
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
end

return M
