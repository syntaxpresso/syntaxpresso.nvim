local n = require("nui-components")

-- @param _signal table: A table that stores the input value and hidden state.
-- @param _title string: The label for the text input border.
-- @param _signal_key string: The key in the signal table to store the input value.
-- @param _signal_hidden string: The key in the signal table to check if the component is hidden.
-- @param _size number|nil: The size of the text input (defaults to 0).
-- @param _autofocus boolean|nil: Whether to autofocus the text input (optional).
-- @param _on_change_callback function|nil: A callback function triggered on value change (optional).
-- @return table: The rendered text input component.
local function text_input_component(_signal, _title, _signal_key, _signal_hidden, _size, _autofocus, _on_change_callback)
  return n.text_input({
    autofocus = _autofocus,
    size = _size or 0,
    value = _signal[_signal_key],
    border_label = _title,
    on_change = function(value, _)
      _signal[_signal_key] = value
      if _on_change_callback then
        _on_change_callback(value, _)
      end
    end,
    hidden = _signal[_signal_hidden] or false,
  })
end

return {
  render_component = text_input_component,
}
