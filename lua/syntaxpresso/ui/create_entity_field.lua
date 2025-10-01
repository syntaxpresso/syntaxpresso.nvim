local n = require("nui-components")
local basic_field = require("syntaxpresso.ui.basic_field")
local enum_field = require("syntaxpresso.ui.enum_field")
local select_one = require("syntaxpresso.ui.components.select_one")
local text = require("syntaxpresso.ui.components.text")

local M = {}

local renderer = n.create_renderer({ height = 7 })

local signal = n.create_signal({
  field_category = "basic",
  next_button_hidden = false,
  previous_button_hidden = true,
  confirm_button_hidden = true
})

local field_category_data = {
  n.node({ text = "Basic Field", is_done = true, id = "basic" }),
  n.node({ text = "Enum Field", is_done = false, id = "enum" }),
  n.node({ text = "ID Field", is_done = false, id = "id" }),
}

local function create_previous_button(child_renderer)
  return n.button({
    flex = 1,
    label = "Previous <-",
    align = "center",
    on_press = function()
      child_renderer:close()  -- Close child renderer first
      renderer:close()        -- Then close parent renderer
      signal.field_category = "basic"
      signal.next_button_hidden = false
      signal.previous_button_hidden = true
      signal.confirm_button_hidden = true
      renderer:render(M.CreateEntityFieldComponent(signal))
    end,
    hidden = false,
  })
end

local function render_next_button(_signal)
  return n.button({
    flex = 1,
    label = "Next ->",
    align = "center",
    global_press_key = "<C-CR>",
    on_press = function()
      renderer:close()
      if _signal.field_category:get_value() == "basic" then
        basic_field.render(create_previous_button)
      elseif _signal.field_category:get_value() == "enum" then
        enum_field.render(create_previous_button)
      elseif _signal.field_category:get_value() == "id" then
      end
      _signal.active_tab = "tab-2"
      _signal.next_button_hidden = true
      _signal.confirm_button_hidden = false
      _signal.previous_button_hidden = false
    end,
    hidden = _signal.next_button_hidden,
  })
end

function M.CreateEntityFieldComponent(_signal)
  return n.tabs(
    { active_tab = _signal.active_tab },
    text.render_component({ text = "New Entity field" }),
    select_one.render_component({
      label = "Category",
      data = field_category_data,
      signal = signal,
      signal_key = "field_category",
      signal_hidden_key = nil,
      autofocus = true,
      size = 3
    }),
    n.columns(
      { flex = 0 },
      render_next_button(_signal)
    )
  )
end

renderer:render(M.CreateEntityFieldComponent(signal))

return M
