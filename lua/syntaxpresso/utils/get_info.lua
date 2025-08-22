local json_parser = require("syntaxpresso.utils.json_parser")

local M = {}

---Get node information at current cursor position
---@param java_executable string Path to the Java executable
---@param callback function Callback function that receives GetInfoResponse or nil
function M.get_node_info(java_executable, callback)
  local file_path = vim.fn.expand("%:p")
  local pos = vim.api.nvim_win_get_cursor(0)

  local cmd_parts = {
    java_executable,
    "get-info",
    "--file-path=" .. file_path,
    "--language=JAVA",
    "--ide=NEOVIM",
    "--line=" .. pos[1],
    "--column=" .. pos[2]
  }

  local output = {}
  vim.fn.jobstart(cmd_parts, {
    on_stdout = function(_, data)
      if data and #data > 0 then
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(output, line)
          end
        end
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 0 and data[1] ~= "" then
        vim.notify("Error getting node info: " .. table.concat(data, "\n"), vim.log.levels.ERROR)
        callback(nil)
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code == 0 and #output > 0 then
        local raw_output = table.concat(output, "")
        local ok, result = json_parser.parse_response(raw_output)

        if ok and type(result) == "table" and result.succeed and result.data then
          ---@cast result DataTransferObject
          ---@type GetInfoResponse
          local response_data = result.data
          callback(response_data)
        else
          vim.notify("Failed to parse get-info response. Raw output: " .. raw_output, vim.log.levels.WARN)
          if ok and type(result) == "table" and result.errorReason then
            vim.notify("Error: " .. result.errorReason, vim.log.levels.ERROR)
          end
          callback(nil)
        end
      else
        vim.notify("Get info command failed with exit code: " .. exit_code, vim.log.levels.ERROR)
        callback(nil)
      end
    end,
  })
end

return M