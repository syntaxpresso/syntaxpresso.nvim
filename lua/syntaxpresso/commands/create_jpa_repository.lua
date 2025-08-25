local json_parser = require("syntaxpresso.utils.json_parser")

local M = {}

function M.execute_create_jpa_repository(java_executable)
  local cmd_parts = { java_executable, "create-jpa-repository" }
  table.insert(cmd_parts, "--cwd=" .. vim.fn.getcwd())
  table.insert(cmd_parts, "--file-path=" .. vim.fn.expand("%:p"))
  table.insert(cmd_parts, "--language=JAVA")
  table.insert(cmd_parts, "--ide=NEOVIM")

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
        vim.notify("Error creating JPA repository: " .. table.concat(data, "\n"), vim.log.levels.ERROR)
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code == 0 and #output > 0 then
        local raw_output = table.concat(output, "")
        local ok, result = json_parser.parse_response(raw_output)

        if ok and type(result) == "table" and result.succeed and result.data then
          ---@cast result DataTransferObject
          ---@type CreateNewFileResponse
          local response_data = result.data
          if response_data.filePath then
            vim.cmd("edit " .. response_data.filePath)
            vim.notify("JPA repository created successfully!", vim.log.levels.INFO)
          end
        else
          if #output > 0 then
            print(raw_output)
          end
          if not ok then
            vim.notify("Failed to parse JPA repository response", vim.log.levels.WARN)
          elseif result and not result.succeed then
            vim.notify("JPA repository creation failed: " .. (result.errorReason or "Unknown error"),
              vim.log.levels.ERROR)
          end
        end
      else
        vim.notify("JPA repository command failed with exit code: " .. exit_code, vim.log.levels.ERROR)
      end
    end,
  })
end

return M
