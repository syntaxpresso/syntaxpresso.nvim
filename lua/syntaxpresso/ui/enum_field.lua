local n = require("nui-components")
local select_one = require("syntaxpresso.ui.components.select_one")
local select_many = require("syntaxpresso.ui.components.select_many")
local text_input = require("syntaxpresso.ui.components.text_input")
local text = require("syntaxpresso.ui.components.text")

local M = {}

local renderer = n.create_renderer()

local signal = n.create_signal({
  field_path = nil,
  field_type = nil,
  field_name = "",
  field_package_path = nil,
  enum_type = "ORDINAL",
  field_length = "255",
  field_length_hidden = true,
  other = {},
})

local enum_type_data = {
  n.node({ text = "ORDINAL", is_done = false, id = "ORDINAL" }),
  n.node({ text = "STRING", is_done = false, id = "STRING" }),
}

local other_data = {
  n.node({ text = "Mandatory", is_done = false, id = "mandatory" }),
  n.node({ text = "Unique", is_done = false, id = "unique" }),
}

local function auto_field_name(type_name)
  -- Convert CamelCase to camelCase for field name
  if type_name and #type_name > 0 then
    return string.lower(string.sub(type_name, 1, 1)) .. string.sub(type_name, 2)
  end
  return ""
end

local function create_field_type_data()
  local enum_data = _G.syntaxpresso_enum_options or {}
  local data = {}
  for _, v in ipairs(enum_data) do
    table.insert(
      data,
      n.node({ text = v.name, type = v.type, package_path = v.package_path, is_done = false, id = v.id })
    )
  end
  return data
end

local function field_type_callback(_signal, _selected_node, _)
  _signal["field_path"] = _selected_node.id
  _signal["field_type"] = _selected_node.type
  _signal["field_package_path"] = _selected_node.package_path
  _signal["field_name"] = auto_field_name(_selected_node.type)
end

local function enum_type_callback(_signal, _selected_node, _)
  if _selected_node.id == "STRING" then
    _signal.field_length_hidden = false
  else
    _signal.field_length_hidden = true
  end
end

local function render_confirm_button()
  return n.button({
    flex = 1,
    label = "Confirm",
    align = "center",
    global_press_key = "<C-CR>",
    on_press = function()
      local result = {
        field_path = signal.field_path:get_value(),
        field_package_path = signal.field_package_path:get_value(),
        field_type = signal.field_type:get_value(),
        field_name = signal.field_name:get_value(),
        enum_type = signal.enum_type:get_value(),
        field_length = signal.field_length:get_value(),
        other = signal.other:get_value(),
      }
      vim.call("CreateEnumEntityFieldCallback", result)
      renderer:close()
    end,
    hidden = signal.confirm_btn_hidden,
  })
end

local function render_component(_previous_button_fn)
  return n.rows(
    { flex = 0 },
    text.render_component({ text = "New Entity field" }),
    text.render_component({ text = "New enum attribute" }),
    select_one.render_component({
      label = "Field type",
      data = create_field_type_data(),
      signal = signal,
      signal_key = "field_type",
      autofocus = true,
      on_select_callback = field_type_callback
    }),
    select_one.render_component({
      label = "Enum type",
      data = enum_type_data,
      signal = signal,
      signal_key = "enum_type",
      on_select_callback = enum_type_callback
    }),
    text_input.render_component({
      title = "Field name",
      signal = signal,
      signal_key = "field_name",
      signal_hidden_key = "field_name_hidden",
      size = 1
    }),
    text_input.render_component({
      title = "Field length",
      signal = signal,
      signal_key = "field_length",
      signal_hidden_key = "field_length_hidden",
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
