local n = require("nui-components")

-- @param opts table: Configuration options for the text input component.
--   @field title string: Label displayed on the text input border.
--   @field signal table: Table storing input value and hidden state.
--   @field signal_key string: Key in the signal table for the input value.
--   @field size number|nil: Width of the text input (defaults to 0).
--   @field signal_hidden_key string: Key in the signal table for hidden state.
--   @field autofocus boolean|nil: If true, autofocuses the text input (optional).
--   @field flex table|nil: Flex layout options for the input (optional).
--   @field on_change_callback function|nil: Callback triggered when value changes (optional).
-- @return table: Rendered text input component.
local function text_input_component(opts)
  return n.text_input({
    flex = opts.flex or nil,
    autofocus = opts.autofocus or false,
    size = opts.size or 0,
    value = opts.signal[opts.signal_key],
    border_label = opts.title,
    on_change = function(value, _)
      opts.signal[opts.signal_key] = value
      if opts.on_change_callback then
        opts.on_change_callback(value, _)
      end
    end,
    hidden = opts.signal[opts.signal_hidden_key] or false,
  })
end

return {
  render_component = text_input_component,
}
