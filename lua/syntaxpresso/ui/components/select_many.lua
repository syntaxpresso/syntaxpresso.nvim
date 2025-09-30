local n = require("nui-components")

-- @param t1 table: The table to be extended.
-- @param t2 table: The table whose elements are appended to t1.
-- @return table: The extended t1 table.
local function extend_array(t1, t2)
  for _, v in ipairs(t2) do
    table.insert(t1, v)
  end
  return t1
end
--
-- @param label string: The label for the tree border.
-- @param data table: A list of nodes for the tree, where each node is a table.
-- @param signal table: A table that stores selected node states.
-- @param signal_key string: The key in the `signal` table to store selected nodes.
-- @param hidden boolean|nil: If true, hides the tree component (defaults to false).
-- @param autofocus boolean|nil: Whether to autofocus the component (optional).
-- @param enable_all_option boolean: If true, enables an "All" option in the tree.
-- @param size number|nil: The size of the tree (optional).
-- @param on_select_callback function|nil: A callback function triggered on node selection (optional).
-- @return table: The rendered tree component.
local function render_component(label, data, signal, signal_key, signal_hidden_key, autofocus, enable_all_option, size,
                                on_select_callback)
  local to_add = {}
  return n.tree({
    border_label = label,
    data = data,
    size = size or #data,
    autofocus = autofocus,
    on_select = function(selected_node, component)
      local tree = component:get_tree()
      local all_enable = enable_all_option or false
      if all_enable and selected_node.text == "All" then
        local all_done = not selected_node.is_done
        for _, node in ipairs(data) do
          node.is_done = all_done
        end
        signal[signal_key] = all_done and vim.tbl_map(function(node)
          return node.id
        end, data) or {}
      else
        local done = not selected_node.is_done
        selected_node.is_done = done
        if done then
          table.insert(to_add, selected_node.id)
          signal[signal_key] = extend_array(to_add, signal[signal_key])
        else
          to_add = vim.tbl_filter(function(value)
            return value ~= selected_node.id
          end, to_add)
          signal[signal_key] = extend_array(to_add, signal[signal_key])
        end
        if all_enable then
          local all_checked = true
          for i = 2, #data do
            if not data[i].is_done then
              all_checked = false
              break
            end
          end
          data[1].is_done = all_checked
        end
      end
      if on_select_callback then
        on_select_callback(signal, selected_node, data)
      end
      tree:render()
    end,
    prepare_node = function(node, line, _)
      if node.is_done then
        line:append("☑", "String")
      else
        line:append("◻", "Comment")
      end
      line:append(" ")
      line:append(node.text)
      return line
    end,
    hidden = signal[signal_hidden_key] or false 
  })
end

return {
  render_component = render_component,
}
