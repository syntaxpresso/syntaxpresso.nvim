local get_info_util = require("syntaxpresso.utils.get_info")

local M = {}

local function execute_get_info(java_executable)
  get_info_util.get_node_info(java_executable, function(response_data)
    if response_data then
      local info_lines = {
        "Node Info:",
        "  File: " .. response_data.filePath,
        "  Language: " .. response_data.language,
        "  Node: " .. response_data.node,
        "  Type: " .. response_data.nodeType,
        "  Text: " .. response_data.nodeText
      }

      vim.notify(table.concat(info_lines, "\n"), vim.log.levels.INFO)
    else
      vim.notify("Failed to get node info", vim.log.levels.WARN)
    end
  end)
end

function M.register(java_executable)
  vim.api.nvim_create_user_command("GetInfo", function()
    execute_get_info(java_executable)
  end, {
    desc = "Get information about the current node under cursor",
  })
end

return M
