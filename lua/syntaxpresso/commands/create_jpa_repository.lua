local json_parser = require("syntaxpresso.utils.json_parser")

local M = {}

local function GetJdtlsClassContent(uri)
  local original_win = vim.api.nvim_get_current_win()
  require('jdtls').open_classfile(uri)
  local new_buf = vim.api.nvim_get_current_buf()
  local content = vim.api.nvim_buf_get_lines(new_buf, 0, -1, false)
  vim.cmd('bdelete! ' .. new_buf)
  vim.api.nvim_set_current_win(original_win)
  return content
end

local function get_symbol_uri(symbol_name, callback)
  vim.lsp.buf_request(0, 'workspace/symbol', { query = symbol_name }, function(err, result)
    if err or not result or vim.tbl_isempty(result) then
      callback(nil, "No symbols found for: " .. symbol_name)
      return
    end
    local uri = result[1].location.uri
    callback(uri, nil)
  end)
end

local function execute_create_jpa_repository_internal(java_executable, file_path, superclass_source, callback)
  local cmd_parts = { java_executable, "create-jpa-repository" }
  table.insert(cmd_parts, "--cwd=" .. vim.fn.getcwd())
  table.insert(cmd_parts, "--file-path=" .. file_path)
  table.insert(cmd_parts, "--language=JAVA")
  table.insert(cmd_parts, "--ide=NEOVIM")
  if superclass_source then
    local base64_source = vim.base64.encode(superclass_source)
    table.insert(cmd_parts, "--superclass-source=" .. base64_source)
  end

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
          callback(result.data, nil)
        else
          if #output > 0 then
            print(raw_output)
          end
          if not ok then
            callback(nil, "Failed to parse JPA repository response")
          elseif result and not result.succeed then
            callback(nil, "JPA repository creation failed: " .. (result.errorReason or "Unknown error"))
          end
        end
      else
        callback(nil, "JPA repository command failed with exit code: " .. exit_code)
      end
    end,
  })
end

local function handle_response(java_executable, original_file_path, response_data)
  if response_data.requiresSymbolSource and response_data.symbol then
    vim.cmd("edit " .. response_data.filePath)

    get_symbol_uri(response_data.symbol, function(uri, err)
      if err then
        vim.notify("Error getting symbol URI: " .. err, vim.log.levels.ERROR)
        return
      end

      local content = GetJdtlsClassContent(uri)
      local source_code = table.concat(content, "\n")

      execute_create_jpa_repository_internal(java_executable, original_file_path, source_code,
        function(new_response, error)
          if error then
            vim.notify(error, vim.log.levels.ERROR)
          else
            handle_response(java_executable, original_file_path, new_response)
          end
        end)
    end)
  else
    if response_data.filePath then
      vim.cmd("edit " .. response_data.filePath)
      vim.notify("JPA repository created successfully!", vim.log.levels.INFO)
    end
  end
end

function M.execute_create_jpa_repository(java_executable)
  local original_file_path = vim.fn.expand("%:p")
  execute_create_jpa_repository_internal(java_executable, original_file_path, nil, function(response_data, error)
    if error then
      vim.notify(error, vim.log.levels.ERROR)
    else
      handle_response(java_executable, original_file_path, response_data)
    end
  end)
end

return M
