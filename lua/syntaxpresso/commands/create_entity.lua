local json_parser = require("syntaxpresso.utils.json_parser")
local get_main_class = require("syntaxpresso.commands.get_main_class")

local M = {}

---Create a new JPA entity
---@param java_executable string Path to the Java executable
---@param package_name string Package name for the entity
---@param file_name string File name for the entity (e.g., "Test.java")
---@param callback function Callback function that receives CreateEntityResponse or nil
local function create_new_jpa_entity(java_executable, package_name, file_name, callback)
  local start_time = vim.loop.hrtime()
  local cmd_parts = {
    java_executable,
    "create-new-jpa-entity",
    "--cwd=" .. vim.fn.getcwd(),
    "--package-name=" .. package_name,
    "--file-name=" .. file_name
  }

  local cmd_string = table.concat(cmd_parts, " ")
  vim.notify("Executing command: " .. cmd_string, vim.log.levels.INFO)
  vim.notify("Current working directory: " .. vim.fn.getcwd(), vim.log.levels.INFO)
  vim.notify("Java executable: " .. java_executable, vim.log.levels.INFO)
  vim.notify("Starting create entity command...", vim.log.levels.INFO)
  
  -- Use vim.system if available (Neovim 0.10+), otherwise fall back to jobstart
  if vim.system then
    vim.system(cmd_parts, { timeout = 30000 }, function(result)
      local end_time = vim.loop.hrtime()
      local duration_ms = (end_time - start_time) / 1000000
      vim.notify(string.format("Command completed in %.2f ms (vim.system)", duration_ms), vim.log.levels.INFO)
      
      if result.code == 0 and result.stdout and result.stdout ~= "" then
        vim.notify("Parsing response...", vim.log.levels.INFO)
        local ok, parsed_result = json_parser.parse_response(result.stdout)

        if ok and type(parsed_result) == "table" and parsed_result.succeed and parsed_result.data then
          ---@cast parsed_result DataTransferObject
          ---@type CreateEntityResponse
          local response_data = parsed_result.data
          vim.notify("Entity parsing successful, executing callback...", vim.log.levels.INFO)
          callback(response_data)
        else
          vim.notify("Failed to parse create-entity response. Raw output: " .. result.stdout, vim.log.levels.WARN)
          if ok and type(parsed_result) == "table" and parsed_result.errorReason then
            vim.notify("Error: " .. parsed_result.errorReason, vim.log.levels.ERROR)
          end
          callback(nil)
        end
      else
        vim.notify("Create entity command failed with exit code: " .. result.code, vim.log.levels.ERROR)
        if result.stderr and result.stderr ~= "" then
          vim.notify("Error: " .. result.stderr, vim.log.levels.ERROR)
        end
        callback(nil)
      end
    end)
  else
    -- Fallback to jobstart for older Neovim versions
    local output = {}
    local job_id = vim.fn.jobstart(cmd_parts, {
      stdout_buffered = true,
      stderr_buffered = true,
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
          vim.notify("Error creating entity: " .. table.concat(data, "\n"), vim.log.levels.ERROR)
          callback(nil)
        end
      end,
      on_exit = function(_, exit_code)
        local end_time = vim.loop.hrtime()
        local duration_ms = (end_time - start_time) / 1000000
        vim.notify(string.format("Command completed in %.2f ms (jobstart)", duration_ms), vim.log.levels.INFO)
        
        if exit_code == 0 and #output > 0 then
          local raw_output = table.concat(output, "")
          vim.notify("Parsing response...", vim.log.levels.INFO)
          local ok, result = json_parser.parse_response(raw_output)

          if ok and type(result) == "table" and result.succeed and result.data then
            ---@cast result DataTransferObject
            ---@type CreateEntityResponse
            local response_data = result.data
            vim.notify("Entity parsing successful, executing callback...", vim.log.levels.INFO)
            callback(response_data)
          else
            vim.notify("Failed to parse create-entity response. Raw output: " .. raw_output, vim.log.levels.WARN)
            if ok and type(result) == "table" and result.errorReason then
              vim.notify("Error: " .. result.errorReason, vim.log.levels.ERROR)
            end
            callback(nil)
          end
        else
          vim.notify("Create entity command failed with exit code: " .. exit_code, vim.log.levels.ERROR)
          callback(nil)
        end
      end,
    })
  end
end

function M.create_entity(java_executable)
  local current_file = debug.getinfo(1, "S").source:sub(2)
  local plugin_root = vim.fn.fnamemodify(current_file, ":h:h:h")
  local ui_path = plugin_root .. "/syntaxpresso/ui/create_entity.lua"

  if vim.fn.filereadable(ui_path) == 0 then
    vim.notify("UI file not found: " .. ui_path, vim.log.levels.ERROR)
    return
  end

  -- Load main class info first to get the package name
  get_main_class.get_main_class_info(java_executable, function(main_class_info)
    local default_package = "com.example"

    if main_class_info and main_class_info.packageName then
      default_package = main_class_info.packageName
    end

    -- Store java_executable and package globally so the UI can access them
    _G.syntaxpresso_java_executable = java_executable
    _G.syntaxpresso_default_package = default_package
    _G.syntaxpresso_create_entity = create_new_jpa_entity

    vim.cmd("luafile " .. ui_path)
  end)
end

function CreateEntityCallback(result)
  local java_executable = _G.syntaxpresso_java_executable
  if not java_executable then
    vim.notify("Java executable not found", vim.log.levels.ERROR)
    return
  end

  create_new_jpa_entity(java_executable, result.entity_package_name, result.entity_name .. ".java",
    function(response_data)
      if response_data then
        vim.notify("Entity created successfully at: " .. response_data.filePath, vim.log.levels.INFO)
        -- Open the created file
        vim.cmd("edit " .. response_data.filePath)
      else
        vim.notify("Failed to create entity", vim.log.levels.ERROR)
      end
    end)
end

M.create_new_jpa_entity = create_new_jpa_entity

return M
