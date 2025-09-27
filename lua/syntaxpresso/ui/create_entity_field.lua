local n = require("nui-components")
local basic_field = require("syntaxpresso.ui.basic_field")
local basic_field_signal = basic_field.create_signal()
local select_one = require("syntaxpresso.ui.select_one")

local signal = n.create_signal({
  active_tab = "tab-1",
  field_category = "basic",
  next_button_hidden = false,
  previous_button_hidden = true,
  confirm_button_hidden = true
})

local renderer = n.create_renderer({ flex = 1, height = 7 })

local function render_field_category_selector()
  local data = {
    n.node({ text = "Basic Field", is_done = true, id = "basic" }),
    n.node({ text = "Enum Field", is_done = false, id = "enum" }),
    n.node({ text = "ID Field", is_done = false, id = "id" }),
  }
  return select_one.render_component(3, "Category", data, "field_category", _signal, true)
end

local function render_main_title()
  return n.paragraph({
    lines = {
      n.line(n.text("New Entity field", "String")),
    },
    align = "center",
    is_focusable = false,
  })
end

local function render_next_button()
  return n.button({
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


renderer:render(n.tabs(
  { active_tab = signal.active_tab },
  render_main_title(),
  n.tab(
    { id = "tab-1" },
    render_field_category_selector()
  ),
  n.tab(
    { id = "tab-2" },
    basic_field.render_component(basic_field_signal)
  ),
  n.tab(
    { id = "tab-3" }
  ),
  render_next_button(),
  render_previous_button()
))
