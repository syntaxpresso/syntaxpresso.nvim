-- build.lua
-- This file is automatically executed by lazy.nvim when the plugin is installed or updated
local installer = require("syntaxpresso.installer")
vim.notify("Syntaxpresso: Checking for core binary updates...", vim.log.levels.INFO)
installer.install(function(path)
	if path then
		vim.notify("Syntaxpresso core binary updated successfully!", vim.log.levels.INFO)
	else
		vim.notify("Syntaxpresso core binary update failed. You may need to install manually.", vim.log.levels.WARN)
	end
end)
