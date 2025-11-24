-- lua/syntaxpresso/version_checker.lua

local M = {}

--- Parse version string "syntaxpresso-core 0.6.2" → "0.6.2"
---@param version_string string
---@return string|nil
function M.parse_version(version_string)
	if not version_string then
		return nil
	end
	local version = version_string:match("(%d+%.%d+%.%d+)")
	return version
end

--- Compare two semver strings
---@param v1 string Version 1 (e.g., "0.6.2")
---@param v2 string Version 2 (e.g., "0.6.3")
---@return number -1 if v1 < v2, 0 if equal, 1 if v1 > v2
function M.compare_versions(v1, v2)
	local function parse_semver(v)
		local major, minor, patch = v:match("(%d+)%.(%d+)%.(%d+)")
		return {
			major = tonumber(major) or 0,
			minor = tonumber(minor) or 0,
			patch = tonumber(patch) or 0,
		}
	end

	local ver1 = parse_semver(v1)
	local ver2 = parse_semver(v2)

	if ver1.major ~= ver2.major then
		return ver1.major < ver2.major and -1 or 1
	elseif ver1.minor ~= ver2.minor then
		return ver1.minor < ver2.minor and -1 or 1
	elseif ver1.patch ~= ver2.patch then
		return ver1.patch < ver2.patch and -1 or 1
	end

	return 0 -- Equal
end

--- Get local installed version by running syntaxpresso-core --version
---@param callback function(version: string|nil)
function M.get_local_version(callback)
	local installer = require("syntaxpresso.installer")
	local executable = installer.get_executable_path()

	-- Check if binary exists
	if vim.fn.executable(executable) ~= 1 then
		callback(nil)
		return
	end

	-- Run: syntaxpresso-core --version
	local stdout_buffer = {}
	vim.fn.jobstart({ executable, "--version" }, {
		on_stdout = function(_, data)
			if data then
				for _, line in ipairs(data) do
					if line ~= "" then
						table.insert(stdout_buffer, line)
					end
				end
			end
		end,
		on_exit = function(_, code)
			if code == 0 then
				local output = table.concat(stdout_buffer, "\n")
				local version = M.parse_version(output)
				callback(version)
			else
				callback(nil)
			end
		end,
	})
end

--- Get latest remote version from GitHub API
---@param callback function(version: string|nil)
function M.get_remote_version(callback)
	local cmd = {
		"curl",
		"-s",
		"--max-time",
		"5", -- 5 second timeout
		"https://api.github.com/repos/syntaxpresso/core/releases/latest",
	}

	local stdout_buffer = {}
	vim.fn.jobstart(cmd, {
		on_stdout = function(_, data)
			if data then
				for _, chunk in ipairs(data) do
					if chunk ~= "" then
						table.insert(stdout_buffer, chunk)
					end
				end
			end
		end,
		on_exit = function(_, code)
			if code ~= 0 then
				callback(nil)
				return
			end

			local response = table.concat(stdout_buffer, "")
			if response == "" then
				callback(nil)
				return
			end

			local ok, release_info = pcall(vim.fn.json_decode, response)

			if ok and release_info and release_info.tag_name then
				-- tag_name is "v0.6.2", strip the "v"
				local version = release_info.tag_name:gsub("^v", "")
				callback(version)
			else
				callback(nil)
			end
		end,
	})
end

--- Check if we should perform an update check based on frequency setting
---@param opts table Plugin options
---@return boolean
function M.should_check_update(opts)
	local frequency = opts.auto_update.frequency

	if frequency == "never" then
		return false
	elseif frequency == "always" then
		return true
	end

	-- Get cache file path
	local data_path = vim.fn.stdpath("data") .. "/syntaxpresso"
	local cache_file = data_path .. "/update_check.json"

	-- Read cache
	local cache = {}
	if vim.fn.filereadable(cache_file) == 1 then
		local content = vim.fn.readfile(cache_file)
		local ok, data = pcall(vim.fn.json_decode, table.concat(content, "\n"))
		if ok then
			cache = data
		end
	end

	local last_check = cache.last_check or 0
	local now = os.time()

	-- Calculate interval
	local interval = 0
	if frequency == "daily" then
		interval = 24 * 60 * 60 -- 1 day in seconds
	elseif frequency == "weekly" then
		interval = 7 * 24 * 60 * 60 -- 7 days
	end

	-- Check if enough time has passed
	if now - last_check >= interval then
		-- Update cache
		vim.fn.mkdir(data_path, "p")
		cache.last_check = now
		local encoded = vim.fn.json_encode(cache)
		vim.fn.writefile({ encoded }, cache_file)
		return true
	end

	return false
end

--- Trigger silent auto-update
---@param local_version string
---@param remote_version string
function M.trigger_silent_update(local_version, remote_version)
	local installer = require("syntaxpresso.installer")

	installer.install(function(path)
		if path then
			vim.notify(
				string.format("✓ Syntaxpresso core updated: v%s → v%s", local_version, remote_version),
				vim.log.levels.INFO
			)
		else
			vim.notify(
				"✗ Syntaxpresso core auto-update failed. Run :SyntaxpressoUpdateCore to retry.",
				vim.log.levels.WARN
			)
		end
	end)
end

--- Prompt user for update (when prompt = true)
---@param local_version string
---@param remote_version string
function M.prompt_update(local_version, remote_version)
	local message = string.format("Syntaxpresso update available: v%s → v%s", local_version, remote_version)

	vim.ui.select({ "Update now", "Skip this version", "Disable auto-update" }, { prompt = message }, function(choice)
		if choice == "Update now" then
			M.trigger_silent_update(local_version, remote_version)
		elseif choice == "Skip this version" then
			-- Store skipped version
			local data_path = vim.fn.stdpath("data") .. "/syntaxpresso"
			local prefs_file = data_path .. "/user_prefs.json"
			vim.fn.mkdir(data_path, "p")

			local prefs = { skipped_version = remote_version }
			local encoded = vim.fn.json_encode(prefs)
			vim.fn.writefile({ encoded }, prefs_file)
		elseif choice == "Disable auto-update" then
			vim.notify(
				"Auto-update disabled. Re-enable in your config or run :SyntaxpressoUpdateCore manually.",
				vim.log.levels.INFO
			)
			-- Note: We can't modify user config, so just inform them
		end
	end)
end

--- Main function to check for updates and prompt/install
---@param opts table Plugin options
function M.check_and_prompt_update(opts)
	-- Check if enabled
	if not opts.auto_update or not opts.auto_update.enabled then
		return
	end

	-- Check frequency
	if not M.should_check_update(opts) then
		return
	end

	-- Get local version
	M.get_local_version(function(local_version)
		if not local_version then
			-- Binary not installed, skip update check
			return
		end

		-- Get remote version
		M.get_remote_version(function(remote_version)
			if not remote_version then
				-- Failed to fetch remote version, skip silently
				return
			end

			-- Compare versions
			local comparison = M.compare_versions(local_version, remote_version)

			if comparison < 0 then
				-- Local version is older, update available

				-- Check if user skipped this version
				local data_path = vim.fn.stdpath("data") .. "/syntaxpresso"
				local prefs_file = data_path .. "/user_prefs.json"
				if vim.fn.filereadable(prefs_file) == 1 then
					local content = vim.fn.readfile(prefs_file)
					local ok, prefs = pcall(vim.fn.json_decode, table.concat(content, "\n"))
					if ok and prefs.skipped_version == remote_version then
						-- User chose to skip this version
						return
					end
				end

				-- Trigger update or prompt
				if opts.auto_update.prompt then
					M.prompt_update(local_version, remote_version)
				else
					M.trigger_silent_update(local_version, remote_version)
				end
			end
		end)
	end)
end

return M
