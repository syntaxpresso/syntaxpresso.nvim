local M = {}

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
  vim.cmd("luafile " .. ui_path)
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
