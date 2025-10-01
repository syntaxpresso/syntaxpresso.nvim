local json_parser = require("syntaxpresso.utils.json_parser")
local get_main_class = require("syntaxpresso.commands.get_main_class")

local M = {}

---Create a new JPA entity
---@param java_executable string Path to the Java executable
---@param package_name string Package name for the entity
---@param file_name string File name for the entity (e.g., "Test.java")
---@param callback function Callback function that receives CreateEntityResponse or nil
local function create_new_jpa_entity(java_executable, package_name, file_name, callback)
  local cmd_parts = {
    java_executable,
    "create-new-jpa-entity",
    "--cwd=" .. vim.fn.getcwd(),
    "--package-name=" .. package_name,
    "--file-name=" .. file_name
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
        vim.notify("Error creating entity: " .. table.concat(data, "\n"), vim.log.levels.ERROR)
        callback(nil)
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code == 0 and #output > 0 then
        local raw_output = table.concat(output, "")
        local ok, result = json_parser.parse_response(raw_output)

        if ok and type(result) == "table" and result.succeed and result.data then
          ---@cast result DataTransferObject
          ---@type CreateEntityResponse
          local response_data = result.data
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

function M.create_entity(java_executable)
  local current_file = debug.getinfo(1, "S").source:sub(2)
  local plugin_root = vim.fn.fnamemodify(current_file, ":h:h:h")
  local ui_path = plugin_root .. "/syntaxpresso/ui/create_entity.lua"

  if vim.fn.filereadable(ui_path) == 0 then
    vim.notify("UI file not found: " .. ui_path, vim.log.levels.ERROR)
    return
  end

  -- Store java_executable globally so the UI can access it
  _G.syntaxpresso_java_executable = java_executable
  -- Make functions available globally
  _G.syntaxpresso_get_main_class = get_main_class.get_main_class_info
  _G.syntaxpresso_create_entity = create_new_jpa_entity

  vim.cmd("luafile " .. ui_path)
end

function CreateEntityCallback(result)
  local java_executable = _G.syntaxpresso_java_executable
  if not java_executable then
    vim.notify("Java executable not found", vim.log.levels.ERROR)
    return
  end

  create_new_jpa_entity(java_executable, result.entity_package_name, result.entity_name .. ".java", function(response_data)
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

