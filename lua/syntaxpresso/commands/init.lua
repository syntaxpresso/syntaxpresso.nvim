local rename = require("syntaxpresso.commands.rename")
local file_operations = require("syntaxpresso.commands.file_operations")
local project_info = require("syntaxpresso.commands.project_info")
local jpa = require("syntaxpresso.commands.jpa")

local M = {}

function M.register(java_executable)
  rename.register(java_executable)
  file_operations.register(java_executable)
  project_info.register(java_executable)
  jpa.register(java_executable)

  vim.notify("Syntaxpresso commands are ready!", vim.log.levels.INFO)
end

return M
