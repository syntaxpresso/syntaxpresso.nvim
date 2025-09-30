local n = require("nui-components")
local basic_field = require("syntaxpresso.ui.basic_field")
local enum_field = require("syntaxpresso.ui.enum_field")
local select_one = require("syntaxpresso.ui.components.select_one")
local text = require("syntaxpresso.ui.components.text")

local renderer = n.create_renderer({ height = 7 })

local main_signal = n.create_signal({
  active_tab = "tab-1",
  subtitle = "Unknown category",
  field_category = "basic",
  next_button_hidden = false,
  previous_button_hidden = true,
  confirm_button_hidden = true
})

-- local enum_field_signal = n.create_signal({
--   field_path = nil,
--   field_type = nil,
--   field_name = "",
--   field_package_path = nil,
--   enum_type = "ORDINAL",
--   field_length = "255",
--   field_length_hidden = true,
--   other = {},
-- })

local basic_field_signal = basic_field.create_signal()
local enum_field_signal = enum_field.create_signal()

local field_category_data = {
  n.node({ text = "Basic Field", is_done = true, id = "basic" }),
  n.node({ text = "Enum Field", is_done = false, id = "enum" }),
  n.node({ text = "ID Field", is_done = false, id = "id" }),
}

local function render_next_button(_signal)
  return n.button({
    flex = 1,
    label = "Next ->",
    align = "center",
    global_press_key = "<C-CR>",
    on_press = function()
      if _signal.field_category:get_value() == "basic" then
        renderer:set_size({ height = 30 })
        _signal["subtitle"] = "New basic type attribute"
      elseif _signal.field_category:get_value() == "enum" then
        renderer:set_size({ height = 20 })
        _signal["subtitle"] = "New enum type attribute"
      elseif _signal.field_category:get_value() == "id" then
        _signal["subtitle"] = "New ID type attribute"
      end
      _signal.active_tab = "tab-2"
      _signal.next_button_hidden = true
      _signal.confirm_button_hidden = false
      _signal.previous_button_hidden = false
      renderer:close()
      renderer:render(Component(_signal))
    end,
    hidden = _signal.next_button_hidden,
  })
end

local function render_previous_button(_signal)
  return n.button({
    flex = 1,
    label = "Previous <-",
    align = "center",
    global_press_key = "<C-CR>",
    on_press = function()
      renderer:set_size({ height = 7 })
      _signal.active_tab = "tab-1"
      _signal.field_category = "basic"
      _signal.next_button_hidden = false
      _signal.previous_button_hidden = true
      _signal.confirm_button_hidden = true
      renderer:close()
      renderer:render(Component(_signal))
    end,
    hidden = _signal.previous_button_hidden,
  })
end

local function render_confirm_button(_signal)
  return n.button({
    flex = 1,
    label = "Confirm",
    align = "center",
    global_press_key = "<C-CR>",
    on_press = function()
      local category = _signal.field_category:get_value()
      if category == "basic" then
        local result = basic_field.get_field_data(basic_field_signal)
        vim.call("CreateBasicEntityFieldCallback", result)
        renderer:close()
      elseif category == "enum" then
        local result = enum_field.get_field_data(enum_field_signal)
        vim.call("CreateEnumEntityFieldCallback", result)
        renderer:close()
        -- elseif category == "id" then
        --   local result = id_field.get_field_data(id_field_signal)
        --   vim.call("CreateIdEntityFieldCallback", result)
        --   renderer:close()
      end
    end,
    hidden = _signal.confirm_button_hidden,
  })
end

local function render_field_component(_signal)
  local category = _signal.field_category:get_value()
  if category == "basic" then
    return basic_field.render_component(basic_field_signal)
  elseif category == "enum" then
    return enum_field.render_component(enum_field_signal)
  else
    return basic_field.render_component(basic_field_signal)
  end
end

function Component(_signal)
  return n.tabs(
    { active_tab = _signal.active_tab },
    text.render_component("New Entity field"),
    n.tab(
      { id = "tab-1" },
      select_one.render_component("Category", field_category_data, main_signal, "field_category", true, 3)
    ),
    n.tab(
      { id = "tab-2" },
      text.render_component(_signal.subtitle:get_value()),
      render_field_component(_signal)
    ),
    n.tab(
      { id = "tab-3" }
    ),
    n.columns(
      { flex = 0 },
      render_next_button(_signal),
      render_previous_button(_signal),
      render_confirm_button(_signal)
    )
  )
end

renderer:render(Component(main_signal))
