local n = require("nui-components")

-- @param title string: Label displayed on the text input border.
-- @param signal table: Table storing input value and hidden state.
-- @param signal_key string: Key in the signal table for the input value.
-- @param size number|nil: Width of the text input (defaults to 0).
-- @param signal_hidden_key string: Key in the signal table for hidden state.
-- @param autofocus boolean|nil: If true, autofocuses the text input (optional).
-- @param flex table|nil: Flex layout options for the input (optional).
-- @param _on_change_callback function|nil: Callback triggered when value changes (optional).
-- @return table: Rendered text input component.
local function text_input_component(title, signal, signal_key, size, signal_hidden_key, autofocus, flex,
                                    _on_change_callback)
  return n.text_input({
    flex = flex or nil,
    autofocus = autofocus,
    size = size or 0,
    value = signal[signal_key],
    border_label = title,
    on_change = function(value, _)
      signal[signal_key] = value
      if _on_change_callback then
        _on_change_callback(value, _)
      end
    end,
    hidden = signal[signal_hidden_key] or false,
  })
end

return {
  render_component = text_input_component,
}
