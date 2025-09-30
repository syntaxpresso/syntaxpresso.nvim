local n = require("nui-components")
local java_types = require("syntaxpresso.utils.java_types")
local select_one = require("syntaxpresso.ui.components.select_one")
local select_many = require("syntaxpresso.ui.components.select_many")
local text_input = require("syntaxpresso.ui.components.text_input")

local M = {}

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
  return select_one.render_component("Field type", data, _signal, "field_type", true, false, 10,
    field_package_type_callback)
end

function M.render_component()
  return n.rows(
    render_field_package_type_component(signal, java_types.get_basic_types()),
    text_input.render_component("Field name", "signal,field_name", 1),
    text_input.render_component("Field length", signal, "field_length", 1, "field_length_hidden"),
    select_one.render_component("Time Zone Storage", time_zone_storage_data, signal, "field_time_zone_storage", false,
      signal.field_time_zone_storage_hidden:get_value()),
    select_one.render_component("Temporal", field_temporal_data, signal, "field_temporal", false,
      signal.field_temporal_hidden:get_value()),
    n.columns(
      { flex = 0 },
      text_input.render_component("Field precision", signal, "field_precision", 1,
        "field_precision_hidden", false, 1),
      text_input.render_component("Field scale", signal, "field_scale", 1, "field_scale_hidden", false, 1)
    ),
    select_many.render_component("Other", other_data, signal, "other", signal.other_hidden:get_value()),
    select_many.render_component("Other", other_extra_data, signal, "other", signal.other_extra_hidden:get_value())
  )
end

function M.get_field_data()
  return {
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
end

return M
