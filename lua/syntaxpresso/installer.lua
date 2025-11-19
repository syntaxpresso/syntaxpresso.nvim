-- lua/syntaxpresso/installer.lua

local M = {}

-- Helper function to get the root path of this plugin.
-- It works by finding the path of the current file.
local function get_plugin_path()
	local str = debug.getinfo(1, "S").source:sub(2)
	return str:match("(.*)/lua/syntaxpresso/installer.lua")
end

-- Define the path where the binary will be stored, now inside the plugin directory.
local plugin_path = get_plugin_path()
local install_dir = plugin_path .. "/bin"
M.install_dir = install_dir

function M.get_install_dir()
	return install_dir
end

-- Returns the expected path to the executable.
function M.get_executable_path()
	local executable_name = "syntaxpresso-core"
	-- Check if running on Windows
	if vim.fn.has("win32") == 1 then
		executable_name = "syntaxpresso-core.exe"
	end
	return install_dir .. "/" .. executable_name
end

-- Determines the correct asset name based on the user's OS and architecture.
local function get_platform_asset_name()
	--[[@diagnostic disable-next-line: undefined-field]]
	local uname = vim.loop.os_uname()
	local os, arch, extension
	extension = "" -- Default to no extension
	if uname.sysname == "Linux" then
		os = "linux"
	elseif uname.sysname == "Darwin" then
		os = "macos"
	elseif uname.sysname:match("Windows") then
		os = "windows"
		extension = ".exe"
	else
		return nil -- Unsupported OS
	end
	-- Map system architecture to the names used in your GitHub releases.
	if uname.machine == "x86_64" or uname.machine == "AMD64" then
		arch = "amd64"
	elseif uname.machine == "arm64" or uname.machine == "aarch64" then
		arch = "arm64"
	else
		return nil -- Unsupported architecture
	end
	-- Construct the final asset name, e.g., "syntaxpresso-linux-amd64"
	return string.format("syntaxpresso-core-%s-%s%s", os, arch, extension)
end

-- Fetches the download URL for the latest release from GitHub.
local function get_latest_release_url(asset_name, callback)
	local cmd = {
		"curl",
		"-s", -- Silent mode
		"https://api.github.com/repos/syntaxpresso/core/releases/latest",
	}
	local stdout_buffer = {}
	vim.fn.jobstart(cmd, {
		on_stdout = function(_, data)
			if data then
				for _, chunk in ipairs(data) do
					table.insert(stdout_buffer, chunk)
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
			if not ok or not release_info then
				callback(nil)
				return
			end
			if release_info and release_info.assets then
				for _, asset in ipairs(release_info.assets) do
					if asset.name == asset_name then
						callback(asset.browser_download_url)
						return
					end
				end
			end
			callback(nil)
		end,
	})
end

-- The main installation function.
function M.install(on_complete)
	-- Make on_complete optional
	on_complete = on_complete or function() end

	local asset_name = get_platform_asset_name()
	if not asset_name then
		vim.notify("Unsupported OS or architecture.", vim.log.levels.ERROR)
		on_complete(nil)
		return
	end
	local executable_path = M.get_executable_path()
	get_latest_release_url(asset_name, function(url)
		if not url then
			vim.notify("Failed to find release URL.", vim.log.levels.ERROR)
			on_complete(nil)
			return
		end
		vim.notify("Downloading syntaxpresso-core to: " .. executable_path, vim.log.levels.INFO)
		vim.fn.mkdir(install_dir, "p")
		local download_cmd = {
			"curl",
			"-L",
			"-o",
			executable_path,
			url,
		}
		vim.fn.jobstart(download_cmd, {
			on_exit = function(_, download_code)
				if download_code == 0 then
					if vim.fn.has("win32") == 0 then
						vim.fn.system({ "chmod", "+x", executable_path })

						if vim.v.shell_error == 0 then
							on_complete(executable_path)
						else
							vim.notify(
								"Failed to make binary executable. `chmod` failed with exit code: " .. vim.v.shell_error,
								vim.log.levels.ERROR
							)
							on_complete(nil)
						end
					else
						-- On Windows, no chmod is needed.
						on_complete(executable_path)
					end
				else
					vim.notify("Download failed with exit code: " .. download_code, vim.log.levels.ERROR)
					on_complete(nil)
				end
			end,
		})
	end)
end

return M
