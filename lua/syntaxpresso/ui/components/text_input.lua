local n = require("nui-components")

-- @param title string: The label for the text input border.
-- @param signal table: A table that stores the input value and hidden state.
-- @param signal_key string: The key in the signal table to store the input value.
-- @param size number|nil: The size of the text input (defaults to 0).
-- @param hidden boolean: Whether the component is hidden.
-- @param autofocus boolean|nil: Whether to autofocus the text input (optional).
-- @param _on_change_callback function|nil: A callback function triggered on value change (optional).
-- @return table: The rendered text input component.
local function text_input_component(title, signal, signal_key, size, hidden, autofocus, _on_change_callback)
  return n.text_input({
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
    hidden = hidden or false,
  })
end

return {
  render_component = text_input_component,
}
