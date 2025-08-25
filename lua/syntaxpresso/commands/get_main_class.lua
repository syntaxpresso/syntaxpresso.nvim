local json_parser = require("syntaxpresso.utils.json_parser")

local M = {}

---Get main class information for the current project
---@param java_executable string Path to the Java executable
---@param callback function Callback function that receives GetMainClassResponse or nil
local function get_main_class_info(java_executable, callback)
  local cmd_parts = {
    java_executable,
    "get-main-class",
    "--cwd=" .. vim.fn.getcwd(),
    "--language=JAVA",
    "--ide=NEOVIM"
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
        vim.notify("Error getting main class: " .. table.concat(data, "\n"), vim.log.levels.ERROR)
        callback(nil)
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code == 0 and #output > 0 then
        local raw_output = table.concat(output, "")
        local ok, result = json_parser.parse_response(raw_output)

        if ok and type(result) == "table" and result.succeed and result.data then
          ---@cast result DataTransferObject
          ---@type GetMainClassResponse
          local response_data = result.data
          callback(response_data)
        else
          vim.notify("Failed to parse get-main-class response. Raw output: " .. raw_output, vim.log.levels.WARN)
          if ok and type(result) == "table" and result.errorReason then
            vim.notify("Error: " .. result.errorReason, vim.log.levels.ERROR)
          end
          callback(nil)
        end
      else
        vim.notify("Get main class command failed with exit code: " .. exit_code, vim.log.levels.ERROR)
        callback(nil)
      end
    end,
  })
end

function M.execute_get_main_class(java_executable)
  get_main_class_info(java_executable, function(response_data)
    if response_data then
      local info_lines = {
        "Main Class Info:",
        "  File Path: " .. response_data.filePath,
        "  Package: " .. response_data.packageName
      }

      vim.notify(table.concat(info_lines, "\n"), vim.log.levels.INFO)
    else
      vim.notify("Failed to get main class info", vim.log.levels.WARN)
    end
  end)
end

M.get_main_class_info = get_main_class_info

return M