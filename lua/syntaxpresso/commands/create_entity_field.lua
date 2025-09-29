local M = {}

local function get_enum_options(java_executable, callback)
  local cwd = vim.fn.getcwd()
  local cmd_parts = { java_executable, "get-all-files" }
  table.insert(cmd_parts, "--cwd=" .. cwd)
  table.insert(cmd_parts, "--file-type=ENUM")
  table.insert(cmd_parts, "--language=JAVA")
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
        vim.notify("Error getting enum options: " .. table.concat(data, "\n"), vim.log.levels.ERROR)
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code == 0 and #output > 0 then
        local raw_output = table.concat(output, "")
        local json_parser = require("syntaxpresso.utils.json_parser")
        local success, parsed = json_parser.parse_response(raw_output)
        if success and parsed and parsed.succeed and parsed.data and parsed.data.response then
          local options = {}
          for _, enum_info in ipairs(parsed.data.response) do
            table.insert(options, {
              name = enum_info.type,
              type = enum_info.type,
              package_path = enum_info.packagePath,
              id = enum_info.filePath
            })
          end
          callback(options)
        else
          vim.notify("Invalid response from get-all-files command", vim.log.levels.ERROR)
          callback({})
        end
      else
        vim.notify("get-all-files command failed with exit code: " .. exit_code, vim.log.levels.ERROR)
        callback({})
      end
    end,
  })
end

function M.create_entity_field(java_executable)
  local current_file = debug.getinfo(1, "S").source:sub(2)
  local plugin_root = vim.fn.fnamemodify(current_file, ":h:h:h")
  local ui_path = plugin_root .. "/syntaxpresso/ui/create_entity_field.lua"

  if vim.fn.filereadable(ui_path) == 0 then
    vim.notify("UI file not found: " .. ui_path, vim.log.levels.ERROR)
    return
  end

  -- Store java_executable globally so the UI can access it
  _G.syntaxpresso_java_executable = java_executable
  
  -- Preload enum options
  get_enum_options(java_executable, function(enum_options)
    _G.syntaxpresso_enum_options = enum_options
    vim.cmd("luafile " .. ui_path)
  end)
end

function CreateBasicEntityFieldCallback(result)
  local field_info = {
    type = "basic",
    package_path = result.field_package_path,
    field_type = result.field_type,
    name = result.field_name,
    length = result.field_length,
    precision = result.field_precision,
    scale = result.field_scale,
    time_zone_storage = result.field_time_zone_storage,
    temporal = result.field_temporal,
    other = result.other,
  }

  vim.notify("Basic field created: " .. vim.inspect(field_info))
end

function CreateEnumEntityFieldCallback(result)
  local field_info = {
    type = "enum",
    field_path = result.field_path,
    package_path = result.field_package_path,
    field_type = result.field_type,
    name = result.field_name,
    enum_type = result.enum_type,
    length = result.field_length,
    other = result.other,
  }

  vim.notify("Enum field created: " .. vim.inspect(field_info))
end

function CreateIdEntityFieldCallback(result)
  local field_info = {
    type = "id",
    package_path = result.field_package_path,
    field_type = result.field_type,
    name = result.field_name,
    id_generation = result.id_generation,
    id_generation_type = result.id_generation_type,
    generator_name = result.generator_name,
    sequence_name = result.sequence_name,
    initial_value = result.initial_value,
    allocation_size = result.allocation_size,
    other = result.other,
  }

  vim.notify("ID field created: " .. vim.inspect(field_info))
end

return M
