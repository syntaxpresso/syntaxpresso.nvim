local n = require("nui-components")

local select_many = require("syntaxpresso.ui.select_many")

local function auto_field_name(type_name)
  -- Convert CamelCase to camelCase for field name
  if type_name and #type_name > 0 then
    return string.lower(string.sub(type_name, 1, 1)) .. string.sub(type_name, 2)
  end
  return ""
end

local M = {}



local function render_field_type_component(_signal, options)
  local data = {}
  for _, v in ipairs(options) do
    table.insert(
      data,
      n.node({ text = v.name, type = v.type, package_path = v.package_path, is_done = false, id = v.id })
    )
  end

  -- Add a placeholder if no options are available
  if #data == 0 then
    table.insert(data, n.node({ text = "No enums found", type = nil, package_path = nil, is_done = false, id = nil }))
  end

  return n.tree({
    autofocus = true,
    size = math.max(#data, 1),
    border_label = "Type",
    data = data,
    on_select = function(selected_node, component)
      -- Don't allow selection of placeholder item
      if not selected_node.id then
        return
      end

      local tree = component:get_tree()
      for _, node in ipairs(data) do
        node.is_done = false
      end
      selected_node.is_done = true
      _signal["field_path"] = selected_node.id
      _signal["field_type"] = selected_node.type
      _signal["field_package_path"] = selected_node.package_path
      _signal["field_name"] = auto_field_name(selected_node.type)
      tree:render()
    end,
    prepare_node = function(node, line, _)
      if node.is_done then
        line:append("◉", "String")
      else
        line:append("○", "Comment")
      end
      line:append(" ")
      line:append(node.text)
      return line
    end,
  })
end

local function render_other_component(_signal)
  local data = {
    n.node({ text = "Mandatory", is_done = false, id = "mandatory" }),
    n.node({ text = "Unique", is_done = false, id = "unique" }),
  }
  return select_many.render_component(nil, "Other", data, _signal, "other")
end

local function render_custom_select_one_component(_signal, _data, _title, _signal_key, _signal_hidden_key)
  return n.tree({
    autofocus = false,
    size = #_data,
    border_label = _title,
    data = _data,
    on_select = function(selected_node, component)
      local tree = component:get_tree()
      for _, node in ipairs(_data) do
        node.is_done = false
      end
      selected_node.is_done = true
      _signal[_signal_key] = selected_node.id
      if selected_node.id == "STRING" then
        _signal[_signal_hidden_key] = false
      else
        _signal[_signal_hidden_key] = true
      end
      tree:render()
    end,
    prepare_node = function(node, line, _)
      if node.is_done then
        line:append("◉", "String")
      else
        line:append("○", "Comment")
      end
      line:append(" ")
      line:append(node.text)
      return line
    end,
  })
end

local function render_text_input_component(signal, title, signal_key, signal_hidden, size)
  return n.text_input({
    flex = 1,
    size = size or 0,
    value = signal[signal_key],
    border_label = title,
    on_change = function(value, _)
      signal[signal_key] = value
    end,
    hidden = signal[signal_hidden] or false,
  })
end

function M.create_signal()
  return n.create_signal({
    field_path = nil,
    field_type = nil,
    field_name = "",
    field_package_path = nil,
    enum_type = "ORDINAL",
    field_length = "255",
    field_length_hidden = true,
    other = {},
  })
end

function M.render_component(signal, java_executable)
  -- Use preloaded enum options from global variable
  local enum_options = _G.syntaxpresso_enum_options or {}

  return n.rows(
    { flex = 0 },
    render_field_type_component(signal, enum_options),
    render_custom_select_one_component(signal, {
      n.node({ text = "ORDINAL", is_done = false, id = "ORDINAL" }),
      n.node({ text = "STRING", is_done = false, id = "STRING" }),
    }, "Enum type", "enum_type", "field_length_hidden"),
    render_text_input_component(signal, "Field name", "field_name", false, 1),
    render_text_input_component(signal, "Field length", "field_length", "field_length_hidden", 1),
    render_other_component(signal)
  )
end

function M.get_field_data(signal)
  return {
    field_path = signal.field_path:get_value(),
    field_package_path = signal.field_package_path:get_value(),
    field_type = signal.field_type:get_value(),
    field_name = signal.field_name:get_value(),
    enum_type = signal.enum_type:get_value(),
    field_length = signal.field_length:get_value(),
    other = signal.other:get_value(),
  }
end

return M
