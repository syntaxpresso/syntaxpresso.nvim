local n = require("nui-components")
local select_one = require("syntaxpresso.ui.components.select_one")
local select_many = require("syntaxpresso.ui.components.select_many")
local text_input = require("syntaxpresso.ui.components.text_input")
local text = require("syntaxpresso.ui.components.text")
local java_types = require("syntaxpresso.utils.java_types")

local M = {}

local renderer = n.create_renderer()

local function entity_to_camel_case(entity_type)
  if entity_type and #entity_type > 0 then
    return string.lower(string.sub(entity_type, 1, 1)) .. string.sub(entity_type, 2)
  end
  return "gen"
end

local signal = n.create_signal({
  field_package_path = "java.lang",
  field_type = "Long",
  field_name = "id",
  id_generation = "auto",
  id_generation_type = "none",
  generator_name = "gen__gen",
  sequence_name = "gen__seq",
  initial_value = "1",
  allocation_size = "50",
  regular_id_generation_type_hidden = false,
  uuid_id_generation_type_hidden = true,
  generator_name_hidden = true,
  sequence_name_hidden = true,
  initial_value_hidden = true,
  allocation_size_hidden = true,
  other = { "mandatory" },
})

-- Load entity info to set proper generator and sequence names
if _G.syntaxpresso_get_entity_info and _G.syntaxpresso_java_executable then
  _G.syntaxpresso_get_entity_info(_G.syntaxpresso_java_executable, function(entity_info)
    if entity_info and entity_info.entityType then
      local camel_case_type = entity_to_camel_case(entity_info.entityType)
      signal.generator_name = camel_case_type .. "__gen"
      signal.sequence_name = camel_case_type .. "__seq"
    else
      -- If entity info fails, keep the default values
      vim.notify("Could not load entity info, using default generator/sequence names", vim.log.levels.WARN)
    end
  end)
end

local uuid_id_generation_type_data = {
  n.node({ text = "None", is_done = false, id = "none" }),
  n.node({ text = "Auto", is_done = false, id = "auto" }),
  n.node({ text = "UUID", is_done = true, id = "uuid" }),
}

local regular_id_generation_type_data = {
  n.node({ text = "None", is_done = false, id = "none" }),
  n.node({ text = "Auto", is_done = true, id = "auto" }),
  n.node({ text = "Identity", is_done = false, id = "identity" }),
  n.node({ text = "Sequence", is_done = false, id = "sequence" }),
}

local generation_type_data = {
  n.node({ text = "None", is_done = true, id = "none" }),
  n.node({ text = "Generate exclusively for entity", is_done = false, id = "entity_exclusive_generation" }),
  n.node({ text = "Provided by ORM", is_done = false, id = "orm_provided" }),
}

local other_data = {
  n.node({ text = "Mandatory", is_done = true, id = "mandatory" }),
  n.node({ text = "Mutable", is_done = false, id = "mutable" }),
}

local function create_field_type_data()
  local id_data = java_types.get_id_types()
  local data = {}
  for _, v in ipairs(id_data) do
    local is_done = false
    if v.id == "java.lang.Long" then
      is_done = true
    end
    table.insert(
      data,
      n.node({ text = v.name, package_path = v.package_path, type = v.type, is_done = is_done, id = v.id })
    )
  end
  return data
end

local function field_type_callback(_signal, _selected_node, _)
  _signal.field_type = _selected_node.type
  _signal.field_package_path = _selected_node.package_path
  if _selected_node.type == "UUID" then
    _signal.uuid_id_generation_type_hidden = false
    _signal.regular_id_generation_type_hidden = true
    _signal.id_generation = "uuid"
  else
    _signal.uuid_id_generation_type_hidden = true
    _signal.regular_id_generation_type_hidden = false
    _signal.id_generation = "auto"
  end
end

local function id_generation_callback(_signal, _selected_node, _)
  if _selected_node.id == "sequence" then
    _signal.id_generation_type_hidden = false
  else
    _signal.id_generation_type_hidden = true
  end
end

local function id_generation_type_callback(_signal, _selected_node, _)
  if _selected_node.id == "entity_exclusive_generation" then
    _signal["generator_name_hidden"] = false
    _signal["sequence_name_hidden"] = false
    _signal["initial_value_hidden"] = false
    _signal["allocation_size_hidden"] = false
  else
    _signal["generator_name_hidden"] = true
    _signal["sequence_name_hidden"] = true
    _signal["initial_value_hidden"] = true
    _signal["allocation_size_hidden"] = true
  end
end

local function render_confirm_button()
  return n.button({
    flex = 1,
    label = "Confirm",
    align = "center",
    global_press_key = "<C-CR>",
    on_press = function()
      local function get_signal_value(field)
        if type(field) == "table" and field.get_value then
          return field:get_value()
        else
          return field
        end
      end

      local result = {
        field_package_path = get_signal_value(signal.field_package_path),
        field_type = get_signal_value(signal.field_type),
        field_name = get_signal_value(signal.field_name),
        id_generation = get_signal_value(signal.id_generation),
        id_generation_type = get_signal_value(signal.id_generation_type),
        generator_name = get_signal_value(signal.generator_name),
        sequence_name = get_signal_value(signal.sequence_name),
        initial_value = get_signal_value(signal.initial_value),
        allocation_size = get_signal_value(signal.allocation_size),
        other = get_signal_value(signal.other),
      }
      vim.call("CreateIdEntityFieldCallback", result)
      renderer:close()
    end,
    hidden = signal.confirm_btn_hidden,
  })
end

local function render_component(_previous_button_fn)
  return n.rows(
    { flex = 0 },
    text.render_component({ text = "New Entity field" }),
    text.render_component({ text = "New ID attribute" }),
    select_one.render_component({
      label = "Field type",
      data = create_field_type_data(),
      signal = signal,
      signal_key = "field_type",
      autofocus = true,
      size = 4,
      on_select_callback = field_type_callback
    }),
    text_input.render_component({
      title = "Field name",
      signal = signal,
      signal_key = "field_name",
      size = 1
    }),
    select_one.render_component({
      label = "Id generation",
      data = regular_id_generation_type_data,
      signal = signal,
      signal_key = "id_generation",
      signal_hidden_key = "regular_id_generation_type_hidden",
    }),
    select_one.render_component({
      label = "Id generation",
      data = uuid_id_generation_type_data,
      signal = signal,
      signal_key = "id_generation",
      signal_hidden_key = "uuid_id_generation_type_hidden",
      on_select_callback = id_generation_callback
    }),
    select_one.render_component({
      label = "Generation type",
      data = generation_type_data,
      signal = signal,
      signal_key = "id_generation_type",
      on_select_callback = id_generation_type_callback
    }),
    text_input.render_component({
      title = "Generator name",
      signal = signal,
      signal_key = "generator_name",
      signal_hidden_key = "generator_name_hidden",
      size = 1
    }),
    text_input.render_component({
      title = "Sequence name",
      signal = signal,
      signal_key = "sequence_name",
      signal_hidden_key = "sequence_name_hidden",
      size = 1
    }),
    text_input.render_component({
      title = "Initial value",
      signal = signal,
      signal_key = "initial_value",
      signal_hidden_key = "initial_value_hidden",
      size = 1
    }),
    text_input.render_component({
      title = "Allocation size",
      signal = signal,
      signal_key = "allocation_size",
      signal_hidden_key = "allocation_size_hidden",
      size = 1
    }),
    select_many.render_component({
      title = "Other",
      data = other_data,
      signal = signal,
      signal_key = "other",
    }),
    n.columns(
      _previous_button_fn(renderer),
      render_confirm_button()
    )
  )
end


function M.render(_previous_button_fn)
  renderer:render(render_component(_previous_button_fn))
end

return M
