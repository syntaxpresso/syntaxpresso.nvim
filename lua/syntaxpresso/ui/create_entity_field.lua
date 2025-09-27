local n = require("nui-components")
local basic_field = require("syntaxpresso.ui.basic_field")
local select_one = require("syntaxpresso.ui.select_one")

local renderer = n.create_renderer({ height = 7 })

local signal = n.create_signal({
  active_tab = "tab-1",
  field_category = "basic",
  next_button_hidden = false,
  previous_button_hidden = true,
  confirm_button_hidden = true
})

local basic_field_signal = basic_field.create_signal()


local function render_main_title()
  return n.paragraph({
    lines = {
      n.line(n.text("New Entity field", "String")),
    },
    align = "center",
    is_focusable = false,
  })
end

local function render_field_category_selector()
  local data = {
    n.node({ text = "Basic Field", is_done = true, id = "basic" }),
    n.node({ text = "Enum Field", is_done = false, id = "enum" }),
    n.node({ text = "ID Field", is_done = false, id = "id" }),
  }
  return select_one.render_component(3, "Category", data, "field_category", signal, true)
end

local function render_next_button()
  return n.button({
    flex = 1,
    label = "Next ->",
    align = "center",
    global_press_key = "<C-CR>",
    on_press = function()
      renderer:set_size({ height = 30 })
      signal.active_tab = "tab-2"
      signal.next_button_hidden = true
      signal.confirm_button_hidden = false
      signal.previous_button_hidden = false
    end,
    hidden = signal.next_button_hidden,
  })
end

local function render_previous_button()
  return n.button({
    flex = 1,
    label = "Previous <-",
    align = "center",
    global_press_key = "<C-CR>",
    on_press = function()
      renderer:set_size({ height = 7 })
      signal.active_tab = "tab-1"
      signal.next_button_hidden = false
      signal.previous_button_hidden = true
      signal.confirm_button_hidden = true
    end,
    hidden = signal.previous_button_hidden,
  })
end

local function render_confirm_button()
  return n.button({
    flex = 1,
    label = "Confirm",
    align = "center",
    global_press_key = "<C-CR>",
    on_press = function()
      local category = signal.field_category:get_value()
      if category == "basic" then
        local result = basic_field.get_field_data(basic_field_signal)
        vim.call("CreateBasicEntityFieldCallback", result)
        renderer:close()
        -- elseif category == "enum" then
        --   local result = enum_field.get_field_data(enum_field_signal)
        --   vim.call("CreateEnumEntityFieldCallback", result)
        --   renderer:close()
        -- elseif category == "id" then
        --   local result = id_field.get_field_data(id_field_signal)
        --   vim.call("CreateIdEntityFieldCallback", result)
        --   renderer:close()
      end
    end,
    hidden = signal.confirm_button_hidden,
  })
end

local function render_field_component()
  local category = signal.field_category:get_value()
  if category == "basic" then
    return basic_field.render_component(basic_field_signal)
  else
    return basic_field.render_component(basic_field_signal)
  end
end

local function render_component()
  return n.tabs(
    { active_tab = signal.active_tab },
    render_main_title(),
    n.tab(
      { id = "tab-1" },
      render_field_category_selector()
    ),
    n.tab(
      { id = "tab-2" },
      render_field_component()
    ),
    n.tab(
      { id = "tab-3" }
    ),
    n.columns(
      { flex = 0 },
      render_next_button(),
      render_previous_button(),
      render_confirm_button()
    )
  )
end
renderer:render(render_component())
