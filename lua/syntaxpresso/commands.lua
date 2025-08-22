local commands = require("syntaxpresso.commands.init")

local M = {}

function M.register(java_executable)
  commands.register(java_executable)
end

return M
