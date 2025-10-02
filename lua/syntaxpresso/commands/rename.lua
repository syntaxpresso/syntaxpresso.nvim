local json_parser = require("syntaxpresso.utils.json_parser")

local M = {}

local function get_current_word(java_executable, callback)
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
        callback(vim.fn.expand("<cword>"))
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
          if response_data.nodeText then
            local clean_text = response_data.nodeText:gsub("[\r\n]", "")
            callback(clean_text)
          else
            callback(vim.fn.expand("<cword>"))
          end
        else
          callback(vim.fn.expand("<cword>"))
        end
      else
        callback(vim.fn.expand("<cword>"))
      end
    end,
  })
end

local function execute_rename(java_executable, new_name)
  local cmd_parts = { java_executable, "rename" }
  local pos = vim.api.nvim_win_get_cursor(0)
  local current_file_path = vim.fn.expand("%:p")

  table.insert(cmd_parts, "--cwd=" .. vim.fn.getcwd())
  table.insert(cmd_parts, "--file-path=" .. current_file_path)
  table.insert(cmd_parts, "--line=" .. pos[1])
  table.insert(cmd_parts, "--column=" .. pos[2])
  table.insert(cmd_parts, "--new-name=" .. new_name)
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
        vim.notify(table.concat(data, "\n"), vim.log.levels.ERROR)
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code == 0 and #output > 0 then
        local raw_output = table.concat(output, "")
        local ok, result = json_parser.parse_response(raw_output)
        if ok and type(result) == "table" and result.succeed and result.data and result.data.filePath then
          ---@cast result DataTransferObject
          ---@type RenameResponse
          local response_data = result.data
          local response_file_path = response_data.filePath
          if response_file_path ~= current_file_path then
            vim.cmd("bdelete")
            vim.cmd("edit " .. response_file_path)
          end
          vim.notify("Rename completed successfully", vim.log.levels.INFO)
        else
          if #output > 0 then
            print(raw_output)
          end
          if not ok then
            vim.notify("Failed to parse rename response", vim.log.levels.WARN)
          elseif result and not (result.succeed) then
            vim.notify("Rename operation failed", vim.log.levels.ERROR)
          end
        end
      else
        vim.notify("Rename command failed with exit code: " .. exit_code, vim.log.levels.ERROR)
      end
    end,
  })
end



function M.rename_with_input(java_executable)
  get_current_word(java_executable, function(current_word)
    vim.ui.input({
      prompt = "Enter new name: ",
      default = current_word,
    }, function(new_name)
      if new_name and new_name ~= "" then
        execute_rename(java_executable, new_name)
      end
    end)
  end)
end

return M
