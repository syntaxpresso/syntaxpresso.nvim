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

---Get all packages with success/error callbacks
---@param cwd string|nil The working directory path (defaults to current working directory)
---@param source_directory string|nil The source directory type ("main" or "test", defaults to "main")
---@param success_callback fun(response: table) Success callback
---@param error_callback fun(error: string)|nil Optional error callback
---@param options table|nil Optional settings
function M.get_all_packages_with_callbacks(cwd, source_directory, success_callback, error_callback, options)
	-- Validate success_callback
	if not success_callback or type(success_callback) ~= "function" then
		error("Success callback function is required")
	end

	M.get_all_packages(cwd, source_directory, function(response, error)
		if error then
			if error_callback then
				error_callback(error)
			else
				vim.notify("Failed to get packages: " .. error, vim.log.levels.ERROR)
			end
		elseif response then
			success_callback(response)
		end
	end, options)
end

---Get all packages and display them in a notification
---@param cwd string|nil The working directory path (defaults to current working directory)
---@param source_directory string|nil The source directory type ("main" or "test", defaults to "main")
---@param options table|nil Optional settings
function M.display_all_packages(cwd, source_directory, options)
	M.get_all_packages_with_callbacks(cwd, source_directory, function(response)
		if response and response.data then
			local data = response.data
			local message = string.format(
				"Found %d packages in %s\nRoot package: %s",
				data.packagesCount or 0,
				cwd or vim.fn.getcwd(),
				data.rootPackageName or "unknown"
			)

			-- Show first few packages as examples
			if data.packages and #data.packages > 0 then
				local package_names = {}
				local count = 0
				for _, pkg in ipairs(data.packages) do
					if count < 5 then -- Show max 5 packages in notification
						table.insert(package_names, pkg.packageName)
						count = count + 1
					else
						break
					end
				end

				if #package_names > 0 then
					message = message .. "\n\nExamples:\n" .. table.concat(package_names, "\n")
					if data.packagesCount > 5 then
						message = message .. "\n... and " .. (data.packagesCount - 5) .. " more"
					end
				end
			end

			vim.notify(message, vim.log.levels.INFO)
		end
	end, function(err)
		vim.notify("Failed to get packages: " .. err, vim.log.levels.ERROR)
	end, options)
end

return M
