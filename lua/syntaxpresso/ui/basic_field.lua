local n = require("nui-components")
local select_one = require("syntaxpresso.ui.components.select_one")
local text_input = require("syntaxpresso.ui.components.text_input")
local text = require("syntaxpresso.ui.components.text")
local java_types = require("syntaxpresso.utils.java_types")

local M = {}

local renderer = n.create_renderer({
  width = 65,
  height = 20,
})

local signal = n.create_signal({
  field_package_path = "java.lang",
  field_type = "String",
  field_name = "",
  field_length = "255",
  other = {},
  field_precision = "19",
  field_scale = "2",
  field_time_zone_storage = nil,
  field_temporal = nil,
  field_length_hidden = false,
  field_temporal_hidden = true,
  field_time_zone_storage_hidden = true,
  field_scale_hidden = true,
  field_precision_hidden = true,
  other_extra_hidden = false,
  other_hidden = true,
})


local has_field_length = {
  "java.lang.String",
  "java.net.URL",
  "java.util.Locale",
  "java.util.Currency",
  "java.lang.Class",
  "java.lang.Character%[%]",
  "char%[%]",
  "java.util.TimeZone",
  "java.time.ZoneOffset",
}

local has_time_zone_storage = {
  "java.time.OffsetDateTime",
  "java.time.OffsetTime",
  "java.time.ZonedDateTime",
}

local has_temporal = {
  "java.util.Date",
  "java.util.Calendar",
}

local has_extra_other = {
  "java.lang.String",
  "java.lang.Byte%[%]",
  "byte%[%]",
  "char%[%]",
  "java.lang.Character%[%]",
  "java.sql.Blob",
  "java.sql.Clob",
  "java.sql.NClob",
}

local time_zone_storage_data = {
  n.node({ text = "NATIVE", is_done = false, id = "NATIVE" }),
  n.node({ text = "NORMALIZE", is_done = false, id = "NORMALIZE" }),
  n.node({ text = "NORMALIZE_UTC", is_done = false, id = "NORMALIZE_UTC" }),
  n.node({ text = "COLUMN", is_done = false, id = "COLUMN" }),
  n.node({ text = "AUTO", is_done = false, id = "AUTO" })
}

local field_temporal_data = {
  n.node({ text = "DATE", is_done = false, id = "DATE" }),
  n.node({ text = "TIME", is_done = false, id = "TIME" }),
  n.node({ text = "TIMESTAMP", is_done = false, id = "TIMESTAMP" }),
}

local other_data = {
  n.node({ text = "Mandatory", is_done = false, id = "mandatory" }),
  n.node({ text = "Unique", is_done = false, id = "unique" }),
}

local other_extra_data = {
  n.node({ text = "Large object", is_done = false, id = "large_object" }),
  n.node({ text = "Mandatory", is_done = false, id = "mandatory" }),
  n.node({ text = "Unique", is_done = false, id = "unique" }),
}


local function extend_array(t1, t2)
  for _, v in ipairs(t2) do
    table.insert(t1, v)
  end
  return t1
end

local function generate_field_package_type_data(_options)
  local data = {}
  for _, v in ipairs(_options) do
    local is_done = false
    if v.id == "java.lang.String" then
      is_done = true
    end
    table.insert(
      data,
      n.node({ text = v.name, package_path = v.package_path, type = v.type, is_done = is_done, id = v.id })
    )
  end
  return data
end

local function field_package_type_callback(_signal, _selected_node, _data)
  local field_length_hidden = true
  local field_precision_hidden = true
  local field_scale_hidden = true
  local field_time_zone_storage_hidden = true
  local field_temporal_hidden = true
  local other_extra_hidden = true
  local other_hidden = false
  for _, node in ipairs(_data) do
    node.is_done = false
  end
  _selected_node.is_done = true
  _signal.field_package_path = _selected_node.package_path
  _signal.field_type = _selected_node.type
  for _, element in ipairs(has_field_length) do
    if _selected_node.id == element then
      field_length_hidden = false
    end
  end
  for _, element in ipairs(has_time_zone_storage) do
    if _selected_node.id == element then
      field_time_zone_storage_hidden = false
    end
  end
  for _, element in ipairs(has_temporal) do
    if _selected_node.id == element then
      field_temporal_hidden = false
    end
  end
  for _, element in ipairs(has_extra_other) do
    if _selected_node.id == element then
      other_hidden = true
      other_extra_hidden = false
    end
  end
  if _selected_node.id == "java.math.BigDecimal" then
    field_precision_hidden = false
    field_scale_hidden = false
  end
  _signal.field_length_hidden = field_length_hidden
  _signal.field_precision_hidden = field_precision_hidden
  _signal.field_scale_hidden = field_scale_hidden
  _signal.field_time_zone_storage_hidden = field_time_zone_storage_hidden
  _signal.field_temporal_hidden = field_temporal_hidden
  _signal.other_hidden = other_hidden
  _signal.other_extra_hidden = other_extra_hidden
end

local function render_field_package_type_component(_signal, _options)
  local data = generate_field_package_type_data(_options)
  return select_one.render_component({
    label = "Field type",
    data = data,
    signal = _signal,
    signal_key = "field_type",
    signal_hidden_key = nil,
    autofocus = true,
    size = 10,
    on_select_callback = field_package_type_callback
  })
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
    hidden = _signal[_signal_hidden_key],
  })
end

local function render_text_input_component(title, signal_key, signal_hidden, size)
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

local function render_custom_select_many_component(_signal, _data, _title, _signal_key, _signal_hidden_key)
  local to_add = {}
  return n.tree({
    size = #_data,
    border_label = _title,
    data = _data,
    on_select = function(selected_node, component)
      local tree = component:get_tree()
      local all_enable = false
      if all_enable and selected_node.text == "All" then
        local all_done = not selected_node.is_done
        for _, node in ipairs(_data) do
          node.is_done = all_done
        end
        _signal[_signal_key] = all_done and vim.tbl_map(function(node)
          return node.id
        end, _data) or {}
      else
        local done = not selected_node.is_done
        selected_node.is_done = done
        if done then
          table.insert(to_add, selected_node.id)
          _signal[_signal_key] = extend_array(to_add, _signal[_signal_key])
        else
          to_add = vim.tbl_filter(function(value)
            return value ~= selected_node.id
          end, to_add)
          _signal[_signal_key] = extend_array(to_add, _signal[_signal_key])
        end
        if all_enable then
          local all_checked = true
          for i = 2, #_data do
            if not _data[i].is_done then
              all_checked = false
              break
            end
          end
          _data[1].is_done = all_checked
        end
      end
      tree:render()
    end,
    prepare_node = function(node, line, _)
      if node.is_done then
        line:append("☑", "String")
      else
        line:append("◻", "Comment")
      end
      line:append(" ")
      line:append(node.text)
      return line
    end,
    hidden = _signal[_signal_hidden_key],
  })
end

local function render_confirm_button()
  return n.button({
    flex = 1,
    label = "Confirm",
    align = "center",
    global_press_key = "<C-CR>",
    padding = { top = 1 },
    on_press = function()
      local result = {
        field_package_path = signal.field_package_path:get_value(),
        field_type = signal.field_type:get_value(),
        field_name = signal.field_name:get_value(),
        field_length = signal.field_length:get_value(),
        field_precision = signal.field_precision:get_value(),
        field_scale = signal.field_scale:get_value(),
        field_time_zone_storage = signal.field_time_zone_storage:get_value(),
        field_temporal = signal.field_temporal:get_value(),
        other = signal.other:get_value(),
      }
      vim.call("CreateBasicEntityFieldCallback", result)
      renderer:close()
    end,
    hidden = signal.confirm_btn_hidden,
  })
end

local function render_component()
  return n.rows(
    { flex = 0 },
    text.render_component({ text = "New basic attribute" }),
    render_field_package_type_component(signal, java_types.get_basic_types()),
    text_input.render_component({
      title = "Field name",
      signal = signal,
      signal_key = "field_name",
      size = 1
    }),
    text_input.render_component({
      title = "Field length",
      signal = signal,
      signal_key = "field_length",
      size = 1,
      signal_hidden_key = "field_length_hidden"
    }),
    select_one.render_component({
      label = "Time Zone Storage",
      data = time_zone_storage_data,
      signal = signal,
      signal_key = "field_time_zone_storage",
      signal_hidden_key = "field_time_zone_storage_hidden"
    }),
    -- render_custom_select_one_component(signal, {
    --   n.node({ text = "NATIVE", is_done = false, id = "NATIVE" }),
    --   n.node({ text = "NORMALIZE", is_done = false, id = "NORMALIZE" }),
    --   n.node({ text = "NORMALIZE_UTC", is_done = false, id = "NORMALIZE_UTC" }),
    --   n.node({ text = "COLUMN", is_done = false, id = "COLUMN" }),
    --   n.node({ text = "AUTO", is_done = false, id = "AUTO" }),
    -- }, "Time Zone Storage", "field_time_zone_storage", "field_time_zone_storage_hidden"),
    render_custom_select_one_component(signal, {
      n.node({ text = "DATE", is_done = false, id = "DATE" }),
      n.node({ text = "TIME", is_done = false, id = "TIME" }),
      n.node({ text = "TIMESTAMP", is_done = false, id = "TIMESTAMP" }),
    }, "Temporal", "field_temporal", "field_temporal_hidden"),
    n.columns(
      { flex = 0, hidden = signal.field_precision_hidden and signal.field_scale_hidden },
      render_text_input_component("Field precision", "field_precision", "field_precision_hidden", 1),
      render_text_input_component("Field scale", "field_scale", "field_scale_hidden", 1)
    ),
    render_custom_select_many_component(signal, {
      n.node({ text = "Mandatory", is_done = false, id = "mandatory" }),
      n.node({ text = "Unique", is_done = false, id = "unique" }),
    }, "Other", "other", "other_hidden"),
    render_custom_select_many_component(signal, {
      n.node({ text = "Large object", is_done = false, id = "large_object" }),
      n.node({ text = "Mandatory", is_done = false, id = "mandatory" }),
      n.node({ text = "Unique", is_done = false, id = "unique" }),
    }, "Other", "other", "other_extra_hidden"),
    render_confirm_button()
  )
end

function M.render()
  renderer:render(render_component())
end

return M
