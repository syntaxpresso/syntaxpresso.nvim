local n = require("nui-components")
local basic_field = require("syntaxpresso.ui.basic_field")
local select_one = require("syntaxpresso.ui.components.select_one")
local text = require("syntaxpresso.ui.components.text")

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

local function render_next_button(_signal)
  return n.button({
    flex = 1,
    label = "Next ->",
    align = "center",
    global_press_key = "<C-CR>",
    on_press = function()
      renderer:close()
      if _signal.field_category:get_value() == "basic" then
        basic_field.render()
      elseif _signal.field_category:get_value() == "enum" then
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
        renderer:close()
      elseif category == "enum" then
        -- local result = enum_field.get_field_data(enum_field_signal)
        -- vim.call("CreateEnumEntityFieldCallback", result)
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

function Component(_signal)
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
      render_next_button(_signal),
      render_previous_button(_signal),
      render_confirm_button(_signal)
    )
  )
end

renderer:render(Component(signal))
