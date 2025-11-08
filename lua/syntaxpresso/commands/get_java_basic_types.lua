local json_parser = require("syntaxpresso.utils.json_parser")

local M = {}

---Get Java basic types based on field type kind
---@param java_executable string Path to the Java executable
---@param field_type_kind string Either "all" or "id"
---@param callback function Callback function that receives array of BasicJavaType or nil
function M.get_java_basic_types(java_executable, field_type_kind, callback)
  local cmd_parts = {
    java_executable,
    "get-java-basic-types",
    "--cwd=" .. vim.fn.getcwd(),
    "--field-type-kind=" .. field_type_kind,
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
        local error_msg = table.concat(data, "\n")
        vim.notify("Error getting Java basic types: " .. error_msg, vim.log.levels.ERROR)
        callback(nil)
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code == 0 and #output > 0 then
        local raw_output = table.concat(output, "")
        local ok, result = json_parser.parse_response(raw_output)

        if ok and type(result) == "table" and result.succeed and result.data then
          ---@cast result DataTransferObject
          ---@type BasicJavaType[]
          local response_data = result.data
          callback(response_data)
        else
          vim.notify("Failed to parse get-java-basic-types response", vim.log.levels.WARN)
          if ok and type(result) == "table" and result.errorReason then
            vim.notify("Error: " .. result.errorReason, vim.log.levels.ERROR)
          end
          callback(nil)
        end
      else
        vim.notify("Get Java basic types command failed with exit code: " .. exit_code, vim.log.levels.ERROR)
        callback(nil)
      end
    end,
  })
end

return M
